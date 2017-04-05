public final class Refresh: Command {
    public let id = "refresh"

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

        let bar = console.loadingBar(title: "Refreshing Token")
        try bar.perform {
            try adminApi.access.refresh(token)
        }
    }
}
