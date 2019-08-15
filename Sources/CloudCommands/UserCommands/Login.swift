import ConsoleKit
import CloudAPI
import Globals

extension Command {
    public typealias Context = CommandContext<Self>
}

struct CloudLogin: Command {
    struct Signature: CommandSignature {
        let email: Option = .email
        let password: Option = .password
    }
    
    /// See `Command`.
    let signature = Signature()

    let help = "logs into vapor cloud."

    /// See `Command`.
    func run(using ctx: Context) throws {
        let e = ctx.load(.email)
        let p = ctx.load(.password, secure: true)
        let token = try UserApi().login(email: e, password: p)
        try token.save()
        ctx.console.output("cloud is ready.".consoleText(.info))
    }
}

