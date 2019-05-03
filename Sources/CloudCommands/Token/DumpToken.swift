import ConsoleKit
import CloudAPI

struct DumpToken: Command {
    struct Signature: CommandSignature {}
    let signature = Signature()
    
    let help: String? = "dump token data. (usually for debugging)"

    func run(using ctx: Context) throws {
        let token = try Token.load()
        ctx.console.info("expires at: ", newLine: false)
        ctx.console.output(token.expiresAt.description.consoleText())
        ctx.console.info("user id:", newLine: false)
        ctx.console.output(token.userID.uuidString.description.consoleText())
        ctx.console.info("token id: ", newLine: false)
        ctx.console.output(token.id.uuidString.consoleText())
        ctx.console.info("token: ", newLine: false)
        ctx.console.output(token.key.consoleText())
    }
}
