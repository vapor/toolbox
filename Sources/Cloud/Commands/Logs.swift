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
        let repo = try getRepo(arguments, console: console, with: token)
        let env: String
        if let name = arguments.option("env") {
            env = name
        } else {
            let e = try selectEnvironment(
                args: arguments,
                forRepo: repo,
                queryTitle: "Which Environment?",
                using: console,
                with: token
            )

            env = e.name
        }

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
