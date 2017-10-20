public final class DatabaseDelete: Command {
    public let id = "delete"
    
    public let help: [String] = [
        "Delete database server."
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
        console.info("Delete database")
        console.warning("WARNING: 24 hours after running this command, your data will be deleted!. Proceed with care.")
        
        let app = try console.application(for: arguments, using: cloudFactory)
        
        try CloudRedis.deleteDBServer(
            console: self.console,
            name: app.name
        )
    }
}



