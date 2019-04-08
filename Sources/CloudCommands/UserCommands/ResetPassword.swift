import Vapor
import CloudAPI
import Globals

struct ResetPassword: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .email
    ]

    /// See `Command`.
    var help: [String] = ["Resets your account's password."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let e = ctx.load(.email)
        todo()
//        return UserApi(on: ctx.container).reset(email: e).map { _ in
//            ctx.console.output("Password has been reset.".consoleText())
//            ctx.console.output("Check: \(e).".consoleText())
//        }
    }
}
