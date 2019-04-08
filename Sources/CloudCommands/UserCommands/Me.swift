import Vapor
import CloudAPI
import Globals

struct Me: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .all
    ]

    /// See `Command`.
    var help: [String] = ["Shows information about user."]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let token = try Token.load()
        todo()
//        let me = UserApi(on: ctx.container).me(token: token)
//        return me.map { me in
//            // name
//            let name = me.firstName + " " + me.lastName
//            ctx.console.output(name.consoleText())
//
//            // email
//            ctx.console.output(me.email.consoleText())
//
//            // id (future others)
//            guard ctx.flag(.all) else { return }
//            ctx.console.output("ID: ", newLine: false)
//            ctx.console.output(me.id.uuidString.consoleText())
//        }
    }
}
