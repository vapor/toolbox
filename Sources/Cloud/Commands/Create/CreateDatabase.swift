public final class CreateDatabase: Command {
    public let id = "db"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The application the environments belong to"
        ]),
        Option(name: "env", help: [
            "The environment to which the database will be added"
        ])
    ]
    
    public let help: [String] = [
        "Adds a database service to an environment."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        _ = try createDatabase(with: arguments)
    }
    
    func createDatabase(with arguments: [String]) throws -> Database {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        
        console.pushEphemeral()
        
        let cloud = try cloudFactory
            .makeAuthedClient(with: console)
        let servers = try cloud.databaseServers().sorted(by: { a, b in
            return a.kind == .mysql || b.kind == .mysql
        })

        console.success("Tip: ", newLine: false)
        console.print("Vapor and Vapor Cloud work best with MySQL databases.")

        let server = try console.giveChoice(
            title: "Which database server?",
            in: servers
        ) { server in
            if let _ = server.organization {
                return "Private \(server.kind.readable) \(server.name)"
            } else {
                if server.kind == .mysql {
                    return "Shared \(server.kind.readable) ($7/month)"
                } else {
                    return "Shared \(server.kind.readable) ($7/month)"
                }
            }
        }
        
        console.popEphemeral()
        
        console.detail("database server", server.name)
        
        let database = try Database(
            id: nil,
            databaseServer: .model(server),
            environment: .model(env)
        )
        
        return try console.loadingBar(title: "Creating database on \(app.repoName):\(env.name)") {
            return try cloudFactory
                .makeAuthedClient(with: console)
                .create(
                    database,
                    for: .model(app)
                )
        }
    }
}

extension DatabaseServer.Kind {
    var readable: String {
        switch self {
        case .aurora:
            return "Aurora"
        case .mongodb:
            return "MongoDB"
        case .mysql:
            return "MySQL"
        case .postgresql:
            return "PostgreSQL"
        }
    }
}
