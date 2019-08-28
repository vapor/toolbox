import CloudAPI
import Globals
import ConsoleKit

struct ResetPassword: Command {

    public struct Signature: CommandSignature {
        @Option(name: "email", short: "e")
        var email: String
    }

    let help = "resets your account's password."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let e = ctx._load(signature.$email)
        try UserApi().reset(email: e)
        ctx.console.output("password has been reset.".consoleText())
        ctx.console.output("check emaail: \(e).".consoleText())
    }
}
extension CommandContext {
        public func _load<V: LosslessStringConvertible>(_ opt: Option<V>, _ message: String? = nil, secure: Bool = false) -> V {
        if let raw = opt.wrappedValue { return raw }
        let msg = message ?? opt.name
        console.pushEphemeral()
        let answer = console.ask(msg.consoleText(), isSecure: secure)
        console.popEphemeral()
        return V.convertOrFail(answer)
    }
}
