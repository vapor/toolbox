import ConsoleKit
import CloudAPI
import Globals

struct CloudLogin: Command {
    struct Signature: CommandSignature {
        @Option(name: "email", short: "e")
        var email: String
        @Option(name: "password", short: "p")
        var password: String
    }

    let help = "logs into vapor cloud."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let e = signature.$email.load(with: ctx)
        let p = signature.$password.load(with: ctx, secure: true)
        let token = try UserApi().login(email: e, password: p)
        try token.save()
        ctx.console.output("cloud is ready.".consoleText(.info))
    }
}

