public final class DatabaseShutdown: Command {
    public let id = "shutdown"
    
    public let help: [String] = [
        "Shutdown your database server. This will keep the data."
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
        console.info("Shutdown database")
        
        let app = try console.application(for: arguments, using: cloudFactory)
        
        try CloudRedis.shutdownDBServer(
            console: self.console,
            name: app.name
        )
    }
}


