public final class DatabaseInspect: Command {
    public let id = "inspect"
    
    public let help: [String] = [
        "Get information about databases linked to an application"
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
        console.info("Inspect database")
        
        let token = try Token.global(with: console)
        let app = try console.application(for: arguments, using: cloudFactory)
        let environments = try applicationApi.environments.all(for: app, with: token)
        
        var envArray: [String] = []
        
        try environments.forEach { val in
            envArray.append("\(val.id ?? "")")
        }
        
        
        
        try CloudRedis.getDatabaseInfo(
            console: self.console,
            cloudFactory: self.cloudFactory,
            environmentArr: envArray,
            application: app.repoName
        )
    }
}

