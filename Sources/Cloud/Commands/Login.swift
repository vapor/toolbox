public final class Login: Command {
    public let id = "login"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you into Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let email = arguments.option("email") ?? console.ask("Email: ")
        let pass = arguments.option("pass") ?? console.ask("Password: ")

        let loginBar = console.loadingBar(title: "Logging in", animated: !arguments.flag("verbose"))
        loginBar.start()
        do {
            let token = try adminApi.login(email: email, pass: pass)
            try token.saveGlobal()
            loginBar.finish()
            console.success("Welcome back.")
        } catch {
            loginBar.fail()
            console.warning("Failed to login user")
            console.warning("User 'vapor cloud signup' if you don't have an account")
            throw "Error: \(error)"
        }
    }
}
