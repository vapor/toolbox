public final class Scale: Command {
    public let id = "scale"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
            ]),
        Option(name: "env", help: [
            "The name of the environment to deploy to.",
            "This will always be required to deploy, however",
            "omitting the flag will result in a selection menu."
            ])
    ]
    
    public let help: [String] = [
        "Scale the amount of replicas"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        let token = try Token.global(with: console)
        
        let replicas = console.ask("Number of replicas").int ?? 0
        console.detail("replicas", "\(replicas)")
        
        let scale = try applicationApi.deploy.scale(
            repo: app.repoName,
            envName: env.name,
            replicas: replicas,
            with: token
        )
        
        console.info("Connecting to build logs ...")
        var waitingInQueue = console.loadingBar(title: "Waiting in Queue")
        defer { waitingInQueue.fail() }
        waitingInQueue.start()
        
        guard let id = try scale.deployment.assertIdentifier().string else {
            throw "Invalid deployment identifier"
        }
        
        var logsBar: LoadingBar?
        try CloudRedis.subscribeDeployLog(id: id) { update in
            waitingInQueue.finish()
            
            if update.type == .start {
                logsBar = self.console.loadingBar(title: update.message)
                logsBar?.start()
            } else if update.success {
                logsBar?.finish()
            } else {
                logsBar?.fail()
            }
            
            if !update.success && !update.message.trim().isEmpty {
                let printable = update.message
                self.console.warning(printable)
                throw "Scale failed."
            }
        }
    }

}


