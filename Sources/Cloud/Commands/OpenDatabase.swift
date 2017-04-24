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
        let app = try cloud.application(for: arguments, using: console)
        let repoName = Identifier(app.repoName)
        let env = try cloud.environment(
            in: .identifier(repoName),
            for: arguments,
            using: console
        )
        
        guard let token = try cloud.accessTokenFactory?.makeAccessToken() else {
            throw "No access token"
        }
        
        let url = try "\(cloudURL)/application/applications/\(app.repoName)/hosting/environments/\(env.name)/database/pma?_authorizationBearer=\(token.makeString())"
        
        console.success("Opening database...")
        try console.foregroundExecute(program: "/bin/sh", arguments: ["-c", "open \(url)"])
    }
}
