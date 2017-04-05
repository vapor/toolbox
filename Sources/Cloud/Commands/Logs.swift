import Foundation

public final class CloudLogs: Command {
    public let id = "logs"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Refreshes vapor token."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let repo = arguments.option("repo")!
        let env = arguments.option("env") ?? "production"
        let since = arguments.option("since") ?? "60s"
        
        try Redis.tailLogs(
            console: console,
            repo: repo,
            envName: env,
            since: since,
            with: token
        )
    }
}
