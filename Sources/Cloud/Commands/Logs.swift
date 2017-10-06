import Foundation

public final class CloudLogs: Command {
    public let id = "logs"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Displays logs from remote Vapor application."
    ]

    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory

    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }

    public func run(arguments: [String]) throws {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(
            on: .model(app),
            for: arguments,
            using: cloudFactory
        )

        let since = arguments.option("since") ?? "60s"

        try CloudRedis.tailLogs(
            console: console,
            repo: app.repoName,
            envName: env.name,
            since: since
        )
    }
}
