public final class CloudRun: Command {
    public let id = "run"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Runs commands on your application"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        // drop 'run'
        let arguments = arguments.dropFirst().array
        guard arguments.count > 1 else {
            console.warning("No command passed to 'vapor cloud run'")
            throw "Expected command, ie 'vapor cloud run prepare'"
        }
        let command = arguments[0]

        let token = try Token.global(with: console)
        let repo = try getRepo(
            arguments,
            console: console,
            with: token
        )

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

        try Redis.runCommand(
            console: console,
            command: command,
            repo: repo,
            envName: env,
            with: token
        )
    }
}
