public final class DatabaseResize: Command {
    public let id = "resize"
    
    public let help: [String] = [
        "Resize your database server."
    ]
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
            ]),
        Option(name: "token", help: [
            "Token of the database server.",
            "This is the variable you use to connect to the server",
            "e.g.: DB_MYSQL_<NAME>"
            ])
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        console.info("Resize database")
        
        console.info("")
        console.warning("Be aware, this feature is still in beta!, use with caution")
        console.info("")
        
        let app = try console.application(for: arguments, using: cloudFactory)
        let db_token = try ServerTokens(console).token(for: arguments, repoName: app.repoName)
        let size = try self.size(for: arguments)
        
        let token = try Token.global(with: console)
        let user = try adminApi.user.get(with: token)
        
        guard console.confirm("Do you want to resize your database server now?") else {
            throw "Cancelled"
        }
        
        try CloudRedis.resizeDBServer(
            console: self.console,
            application: app.name,
            token: db_token,
            email: user.email,
            newSize: "\(size)"
        )
    }
    
    private func size(for arguments: [String]) throws -> Size {
        let size: Size
        
        console.pushEphemeral()
        
        size = try console.giveChoice(
            title: "Which size?",
            in: Size.all
        ) { type in
            switch type {
            case .free:
                return "(Dev) Free $0/month - (256MB memory / 10K rows / 20 connections)"
            case .hobby:
                return "(Dev) Hobby $9/month - (256MB memory / 5M rows / 20 connections)"
            }
        }
        
        console.popEphemeral()
        
        console.detail("size", "\(size)")
        return size
    }
}




