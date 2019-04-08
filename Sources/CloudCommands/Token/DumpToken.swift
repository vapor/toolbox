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
        ctx.console.info("Expires At: ", newLine: false)
        ctx.console.output(token.expiresAt.description.consoleText())
        ctx.console.info("User ID:", newLine: false)
        ctx.console.output(token.userID.uuidString.description.consoleText())
        ctx.console.info("ID: ", newLine: false)
        ctx.console.output(token.id.uuidString.consoleText())
        ctx.console.info("Token: ", newLine: false)
        ctx.console.output(token.key.consoleText())
        return ctx.done
    }
}
