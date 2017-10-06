public final class OpenDatabase: Command {
    public let id = "database"
    
    public let signature: [Argument] = [
        Option(name: "app"),
        Option(name: "env")
    ]
    
    public let help: [String] = [
        "Opens a database editor for the selected environment in your web browser"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try console.application(for: arguments, using: cloudFactory)
        let repoName = Identifier(app.repoName)
        let env = try console.environment(
            on: .identifier(repoName),
            for: arguments,
            using: cloudFactory
        )
        
        guard let token = try cloud.accessTokenFactory?.makeAccessToken() else {
            throw "No access token"
        }
        
        let url = try "\(cloudURL)/application/applications/\(app.repoName)/hosting/environments/\(env.name)/database/pma?_authorizationBearer=\(token.makeString())"
        
        console.success("Opening database...")
        
        try console.open(url)
    }
}

extension ConsoleProtocol {
    func open(_ url: String) throws {
        #if os(Linux)
            let open = "xdg-open"
        #else
            let open = "open"
        #endif
        try foregroundExecute(program: "/bin/sh", arguments: ["-c", "\(open) \(url)"])
    }
}
