import Vapor
import CloudAPI

struct Me: MyCommand {
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

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let token = try Token.load()
        let me = try UserApi.me(token: token)
        ctx.console.output("email:")
        ctx.console.output(me.email.consoleText())
        ctx.console.output("name:")
        let name = me.firstName + " " + me.lastName
        ctx.console.output(name.consoleText())

        let all = ctx.options["all"]?.bool == true
        guard all else { return }
        ctx.console.output("ID:")
        ctx.console.output(me.id.uuidString.consoleText())
    }
}
