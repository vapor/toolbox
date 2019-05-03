import CloudAPI
import Globals
import ConsoleKit

struct ResetPassword: Command {
    public struct Signature: CommandSignature {
        public let email: Option = .email
    }
    
    /// See `Command`.
    public let signature = Signature()
    
    var help: String? = "resets your account's password."

    /// See `Command`.
    func run(using ctx: CommandContext<ResetPassword>) throws {
        let e = ctx.load(.email)
        try UserApi().reset(email: e)
        ctx.console.output("password has been reset.".consoleText())
        ctx.console.output("check emaail: \(e).".consoleText())
    }
}
