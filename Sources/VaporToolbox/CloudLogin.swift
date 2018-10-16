import Vapor

struct CloudLogin: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "email", short: "e", default: nil, help: ["the email to use when logging in"]),
        .value(name: "password", short: "p", default: nil, help: ["the password to use when logging in"])
    ]

    /// See `Command`.
    var help: [String] = ["Logs into Vapor Cloud"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = CloudLoginRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudLoginRunner {
    let ctx: CommandContext

    func run() throws {
        let e = email()
        let p = password()
        let token = try UserApi.login(email: e, password: p)
        try token.save()
        ctx.console.output("Welcome to Cloud".consoleText(.info))
    }

    func email() -> String {
        if let email = ctx.options["email"] { return email }
        return ctx.console.ask("email")
    }

    func password() -> String {
        if let pass = ctx.options["password"] { return pass }
        return ctx.console.ask("password", isSecure: true)
    }
}
