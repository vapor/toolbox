public final class DatabaseLogin: Command {
    public let id = "login"
        
    public let help: [String] = [
        "Login to a database CLI interface"
    ]
    
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
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        console.info("Login to database server CLI interface.")
        
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        
        try CloudRedis.getDatabaseInfo(
            console: self.console,
            cloudFactory: self.cloudFactory,
            environment: "\(env.id ?? "")"
        )
    }
}
