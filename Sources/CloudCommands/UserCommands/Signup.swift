import Vapor
import CloudAPI
import Globals

struct CloudSignup: Command {
    struct Signature: CommandSignature {
        let first: Option = .firstName
        let last: Option = .lastName
        let org: Option = .org
        let email: Option = .email
        let password: Option = .password
    }
    
    /// See `Command`.
    let signature = Signature()
    
    let help: String? = "creates a new account for vapor cloud."
    
    /// See `Command`.
    func run(using ctx: Context) throws {
        let f = try ctx.loadAndDisplay(.firstName)
        let l = try ctx.loadAndDisplay(.lastName)
        let o = try ctx.loadAndDisplay(.org)
        let e = try ctx.loadAndDisplay(.email)
        let p = try ctx.loadAndDisplay(.password, secure: true)

        let api = UserApi()
        let _ = try api.signup(
            email: e,
            firstName: f,
            lastName: l,
            organizationName: o,
            password: p
        )
        ctx.console.output("success. welcome to cloud..".consoleText(.info))
        
//        todo()
//        let api = UserApi(on: ctx.container)
//        let user = api.signup(
//            email: e,
//            firstName: f,
//            lastName: l,
//            organizationName: o,
//            password: p
//        )
//        return user.map { _ in
//            ctx.console.output("Welcome to Cloud".consoleText(.info))
//        }
    }
}

extension CommandContext {
    func loadAndDisplay<T: LosslessStringConvertible>(_ opt: Option<T>, secure: Bool = false) throws -> String {
        let val = load(opt, secure: secure).description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !val.isEmpty else { throw "No value entered for \(opt.name)" }
        display(opt, value: val, secure: secure)
        return val
    }

    func display<T: LosslessStringConvertible>(_ opt: Option<T>, value: String, secure: Bool) {
        console.output(opt.name.consoleText(.info), newLine: false)
        let text = secure ? "*****" : value.consoleText()
        console.output(": " + text)
    }
}
