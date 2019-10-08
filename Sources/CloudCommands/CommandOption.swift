import ConsoleKit
import Globals

extension LosslessStringConvertible {
    static func convertOrFail(_ raw: String) -> Self {
        if let val = self.init(raw) { return val }
        else { fatalError("unable to convert \(raw) to '\(type(of: Self.self))'") }
    }
}

extension Option {
    func load(with ctx: CommandContext, _ message: String? = nil, secure: Bool = false) -> Value {
        if let raw = self.wrappedValue { return raw }
        let msg = message ?? self.name
        ctx.console.pushEphemeral()
        let answer = ctx.console.ask(msg.consoleText(), isSecure: secure)
        ctx.console.popEphemeral()
        return Value.convertOrFail(answer)
    }
}
