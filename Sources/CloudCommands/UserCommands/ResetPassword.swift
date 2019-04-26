import Vapor
import CloudAPI
import Globals
import ConsoleKit

struct ResetPassword: Command {
    
    public struct Signature: CommandSignature {
        public let email = Option<String>(name: "email", short: "e", type: .value, help: "the email to use.")
    }
    
    /// See `Command`.
    public let signature = Signature()
    
    var help: String? = "resets your account's password."
    
    /// See `Command`.
//    var arguments: [Argument] = []
//
//    /// See `Command`.
//    var options: [Option] = [
//    { todo() }()
////        .email
//    ]

    /// See `Command`.
//    var help: [String] = ["Resets your account's password."]

    /// See `Command`.
    func run(using ctx: CommandContext<ResetPassword>) throws {
//        let e = ctx.load(.email)
        todo()
//        return UserApi(on: ctx.container).reset(email: e).map { _ in
//            ctx.console.output("Password has been reset.".consoleText())
//            ctx.console.output("Check: \(e).".consoleText())
//        }
    }
}
