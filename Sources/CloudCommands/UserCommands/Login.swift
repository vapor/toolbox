import Vapor
import CloudAPI
import Globals

struct CloudLogin: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .email,
        .password
    ]

    /// See `Command`.
    var help: [String] = ["Logs into Vapor Cloud"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let e = ctx.load(.email)
        let p = ctx.load(.password, secure: true)
        todo()
//        let token = UserApi(on: ctx.container).login(email: e, password: p)
//        return token.map { token in
//            try token.save()
//            ctx.console.output("Cloud is Ready".consoleText(.info))
//        }
    }
}

