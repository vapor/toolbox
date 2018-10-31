import Vapor
import CloudAPI

struct DumpToken: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Dump token data"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let token = try Token.load()
        ctx.console.output("Token:", newLine: false)
        ctx.console.output(token.token.consoleText())
        ctx.console.output("Expires At: ", newLine: false)
        ctx.console.output(token.expiresAt.description.consoleText())
        ctx.console.output("User ID:", newLine: false)
        ctx.console.output(token.userID.uuidString.description.consoleText())
        ctx.console.output("ID:", newLine: false)
        ctx.console.output(token.id.uuidString.consoleText())
        return .done(on: ctx.container)
    }
}
