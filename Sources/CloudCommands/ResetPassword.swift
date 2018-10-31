import Vapor
import CloudAPI

struct ResetPassword: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(
            name: "email",
            short: "e",
            default: nil,
            help: ["The email to reset."]
        ),
        ]

    /// See `Command`.
    var help: [String] = ["Resets your account's password."]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = ResetPasswordRunner(ctx: ctx)
        try runner.run()
    }
}

struct ResetPasswordRunner {
    let ctx: CommandContext

    func run() throws {
        let e = email()
        try UserApi(on: ctx.container).reset(email: e)
        ctx.console.output("Password has been reset.".consoleText())
        ctx.console.output("Check your email.".consoleText())
    }

    func email() -> String {
        if let email = ctx.options["email"] { return email }
        return ctx.console.ask("email")
    }
}
