public final class DatabaseList: Command {
    public let id = "list"
    
    public let help: [String] = [
        "List all database servers for a specific application, including their status"
    ]
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
            ])
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        console.info("List database servers")
        
        let app = try console.application(for: arguments, using: cloudFactory)
        
        let token = try Token.global(with: console)
        let user = try adminApi.user.get(with: token)
        
        try CloudRedis.getDatabaseList(
            console: self.console,
            cloudFactory: self.cloudFactory,
            application: app.repoName,
            email: user.email
        )
    }
}



