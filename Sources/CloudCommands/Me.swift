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
        return me.map { me in
            // name
            let name = me.firstName + " " + me.lastName
            ctx.console.output(name.consoleText())

            // email
            ctx.console.output(me.email.consoleText())

            // id (future others)
            let all = ctx.options["all"]?.bool == true
            guard all else { return }
            ctx.console.output("id: ", newLine: false)
            ctx.console.output(me.id.uuidString.consoleText())
        }
    }
}
