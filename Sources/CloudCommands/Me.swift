import Vapor
import CloudAPI

struct Me: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .flag(
            name: "all",
            short: "a",
            help: ["include more data about user"]
        ),
    ]

    /// See `Command`.
    var help: [String] = ["Shows information about user."]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let token = try Token.load()
        let me = try UserApi(on: ctx.container).me(token: token)
        ctx.console.output("name:".consoleText(.info))
        return me.map { (me) -> (Void) in
            let name = me.firstName + " " + me.lastName
            ctx.console.output("email:")
            ctx.console.output(me.email.consoleText())
            ctx.console.output(name.consoleText())

            let all = ctx.options["all"]?.bool == true
            guard all else { return }
            ctx.console.output("id:")
            ctx.console.output(me.id.uuidString.consoleText())
//            return .done(on: ctx.container)
        }
//        let name = me.firstName + " " + me.lastName
//        ctx.console.output("email:")
//        ctx.console.output(me.email.consoleText())
//        ctx.console.output(name.consoleText())
//
//        let all = ctx.options["all"]?.bool == true
//        guard all else { return }
//        ctx.console.output("id:")
//        ctx.console.output(me.id.uuidString.consoleText())
//        return .done(on: ctx.container)
    }

    /// See `Command`.
//    func trigger(with ctx: CommandContext) throws {
//        let token = try Token.load()
//        let me = try UserApi(on: ctx.container).me(token: token)
//        ctx.console.output("name:".consoleText(.info))
//        let name = me.firstName + " " + me.lastName
//        ctx.console.output("email:")
//        ctx.console.output(me.email.consoleText())
//        ctx.console.output(name.consoleText())
//
//        let all = ctx.options["all"]?.bool == true
//        guard all else { return }
//        ctx.console.output("id:")
//        ctx.console.output(me.id.uuidString.consoleText())
//    }
}
