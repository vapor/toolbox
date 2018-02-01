public final class CloudRun: Command {
    public let id = "run"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Runs commands on your application"
    ]

    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory

    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }

    public func run(arguments: [String]) throws {
        // drop 'run'
        guard arguments.count >= 1 else {
            console.warning("No command passed to 'vapor cloud run'")
            throw "Expected command, ie 'vapor cloud run prepare'"
        }


        let command = arguments.joined(separator: " ")

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

        try CloudRedis.runCommand(
            console: console,
            command: command,
            repo: app.repoName,
            envName: env.name,
            with: token
        )
    }
}
