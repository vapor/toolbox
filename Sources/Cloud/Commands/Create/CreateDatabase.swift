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
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        
        let servers = try cloud.databaseServers()
        let server = try console.giveChoice(
            title: "Which database server?",
            in: servers
        ) { server in
            return "\(server.name) (\(server.kind))"
        }
        console.detail("database server", server.name)
        
        let database = try Database(
            id: nil,
            databaseServer: .model(server),
            environment: .model(env)
        )
        
        return try console.loadingBar(title: "Creating database on \(app.repoName):\(env.name)") {
            return try cloud.create(
                database,
                for: .model(app)
            )
        }
    }
}
