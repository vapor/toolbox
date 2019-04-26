import Vapor
import CloudAPI
import Globals

//extension Option where Value == String {
//    static var email: Option<String> { return .init(name: "email", short: "e", type: .value, help: "the email to use.") }
//    static var password: Option<String> { return .init(name: "password", short: "p", type: .value, help: "the password to use.") }
//}

extension Command {
    typealias Context = CommandContext<Self>
}

struct CloudLogin: Command {
    public struct Signature: CommandSignature {
        public let email = Option.email
        public let password = Option.password
    }
    
    /// See `Command`.
    public let signature = Signature()
    
//    /// See `Command`.
//    var arguments: [CommandArgument] = []
//
//    /// See `Command`.
//    var options: [CommandOption] = [
//        .email,
//        .password
//    ]

    /// See `Command`.
    var help: String? = "logs into vapor cloud."
//    var help: [String] = ["Logs into Vapor Cloud"]

    /// See `Command`.
    func run(using ctx: Context) throws {
//        let e = ctx.load(.email)
//        let p = ctx.load(.password, secure: true)
        todo()
//        let token = UserApi(on: ctx.container).login(email: e, password: p)
//        return token.map { token in
//            try token.save()
//            ctx.console.output("Cloud is Ready".consoleText(.info))
//        }
    }
}

