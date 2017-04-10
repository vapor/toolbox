import libc

public final class Me: Command {
    public let id = "me"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Shows info about the currently logged in user."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let bar = console.loadingBar(title: "Fetching User")
        let user = try bar.perform {
            try adminApi.user.get(with: token)
        }
        console.success("Name: ", newLine: false)
        console.print(user.name.full)
        console.success("Email: ", newLine: false)
        console.print("\(user.email)")

        guard arguments.flag("id") else { return }
        if let id = user.id?.string {
            console.success("Id: ", newLine: false)
            console.print(id)
        }
    }
}
