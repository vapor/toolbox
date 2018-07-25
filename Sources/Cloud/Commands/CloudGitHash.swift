public final class CloudGitHash: Command {
    public let id = "git-hash"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Get the Git hash deployed live"
    ]

    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory

    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }

    public func run(arguments: [String]) throws {
        
        let app = try console.application(for: arguments, using: cloudFactory)
        let repoName = Identifier(app.repoName)
        let env = try console.environment(
            on: .identifier(repoName),
            for: arguments,
            using: cloudFactory
        )

        let cloud = try cloudFactory.makeAuthedClient(with: console)
        guard let token = try cloud.accessTokenFactory?.makeAccessToken() else {
            throw "No access token"
        }

        try CloudRedis.gitHash(
            console: console,
            repo: app.repoName,
            envName: env.name,
            with: token
        )
    }
}
