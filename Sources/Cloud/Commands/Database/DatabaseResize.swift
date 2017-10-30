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
        
        let app = try console.application(for: arguments, using: cloudFactory)
        let db_token = try self.token(for: arguments)
        let size = try self.size(for: arguments)
        
        let token = try Token.global(with: console)
        let user = try adminApi.user.get(with: token)
        
        guard console.confirm("This will restart your database server, and will cause downtime, are you sure you want to continue?") else {
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
                return "(Dev) Free $0/month - (256mb memory - 10,000 records - 20 connections - no backups)"
            case .hobby:
                return "(Dev) Hobby $9/month - (256mb memory - 5,000,000 records - 20 connections - no backups)"
            }
        }
        
        console.popEphemeral()
        
        console.detail("size", "\(size)")
        return size
    }
    
    private func token(for arguments: [String]) -> String {
        let token: String
        if let chosen = arguments.option("token") {
            token = chosen
        } else {
            console.error("Please define server token")
            exit(1)
        }
        console.detail("token", token)
        return token
    }
}




