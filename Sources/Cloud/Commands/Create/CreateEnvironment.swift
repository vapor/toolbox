public final class CreateEnvironment: Command {
    public let id = "env"
    
    public let signature: [Argument] = [
        Option(name: "app", help: ["The application to create this environment under"]),
        Option(name: "name", help: [
            "The name of this environment",
            "Good environment names resemble git branch names."
        ]),
        Option(name: "branch", help: [
            "The default branch used for deployments",
            "to this environment"
        ]),
        Option(name: "replicaSize", help: [
            "The size of replicas to use for this environment"
        ])
    ]
    
    public let help: [String] = [
        "Creates a new environment."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        _ = try createEnvironment(with: arguments)
    }
    
    func createEnvironment(with arguments: [String]) throws -> Environment {
        let app = try console.application(for: arguments, using: cloudFactory)
        
        // verify this app has hosting first
        do {
            _ = try console.hosting(on: .model(app), for: arguments, using: cloudFactory)
        } catch {
            console.warning("No hosting service found.")
            console.print("Use: vapor cloud create hosting")
            throw "Hosting service required"
        }
        
        let name: String
        if let n = arguments.option("name") {
            name = n
        } else {
            console.print("Environment names correspond to:")
            console.print("- Subfolders of Config, e.g., Config/staging/*.json")
            console.print("- Hosted URLs, e.g., http://myproject-staging.vapor.cloud")
            console.print("Good environment names resemble git branch names,")
            console.print("i.e., develop, staging, production, testing.")
            name = console.ask("What name for this environment?")
            console.clear(lines: 7)
        }
        console.detail("environment", name)
        
        let branch: String
        if let b = arguments.option("branch") {
            branch = b
        } else {
            branch = console.ask("What 'git' branch should we deploy for this Environment?")
            console.clear(lines: 2)
        }
        console.detail("default branch", branch)
        
        console.pushEphemeral()
        
        let replicaSize: ReplicaSize
        if let size = arguments.option("replicaSize") {
            replicaSize = try ReplicaSize(node: size)
        } else {
            replicaSize = try console.giveChoice(title: "What size replica(s)?", in: ReplicaSize.all)
        }
        
        console.popEphemeral()
        
        console.detail("replica size", "\(replicaSize)")
        try console.verifyAboveCorrect()
        
        
        return try console.loadingBar(title: "Creating \(name) environment") { () -> Environment in
            let cloud = try cloudFactory.makeAuthedClient(with: console)
            
            let env = Environment(
                id: nil,
                hosting: .identifier(""),
                name: name,
                replicas: 0,
                replicaSize: replicaSize,
                defaultBranch: branch
            )
            
            return try cloud.create(env, for: .model(app))
        }
    }

}
