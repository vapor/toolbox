import Vapor
import CloudAPI

struct ResetPassword: Command {
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
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = ResetPasswordRunner(ctx: ctx)
        return runner.run()
    }
}

struct ResetPasswordRunner {
    let ctx: CommandContext

    func run() -> Future<Void> {
        let e = email()
        return UserApi(on: ctx.container).reset(email: e).map { _ in
            self.ctx.console.output("Password has been reset.".consoleText())
            self.ctx.console.output("Check your email.".consoleText())
        }
    }

    func email() -> String {
        if let email = ctx.options["email"] { return email }
        return ctx.console.ask("email")
    }
}
