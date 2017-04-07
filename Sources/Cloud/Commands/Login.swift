import libc

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
        let pass = arguments.option("pass") ?? console.ask("Password: ", secure: true)

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

extension ConsoleProtocol {
        /**
         Requests input from the console
         after displaying the desired prompt.
         */
    public func ask(_ prompt: String, style: ConsoleStyle = .info, secure: Bool) -> String {
        output(prompt, style: style)
        output("> ", style: style, newLine: false)
        if secure {
            return secureInput()
        } else {
            return input()
        }
    }

    // TODO: Remove when console is upgraded
    fileprivate func secureInput() -> String {
        // http://stackoverflow.com/a/30878869/2611971
        let entry: UnsafeMutablePointer<Int8> = getpass("")
        let pointer: UnsafePointer<CChar> = .init(entry)
        var pass = String(validatingUTF8: pointer) ?? ""
        if pass.hasSuffix("\n") {
            pass = pass.makeBytes().dropLast().makeString()
        }
        return pass
    }
}
