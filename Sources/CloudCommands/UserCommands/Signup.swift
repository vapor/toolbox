import ConsoleKit
import CloudAPI
import Globals

struct CloudSignup: Command {
    struct Signature: CommandSignature {
        @Option(name: "first-name", short: "f", help: "your first name")
        var first: String?
        @Option(name: "last-name", short: "l", help: "your last name")
        var last: String?
        @Option(name: "org", short: "o", help: "name of your organization ('MyOrg')")
        var org: String?
        @Option(name: "email", short: "e", help: "email to signup with")
        var email: String?
        @Option(name: "password", short: "p", help: "the password to signupt with")
        var password: String?
    }
    
    let help = "creates a new account for vapor cloud."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature sig: Signature) throws {
        let f = try ctx.loadAndDisplay(sig.$first)
        let l = try ctx.loadAndDisplay(sig.$last)
        let o = try ctx.loadAndDisplay(sig.$org)
        let e = try ctx.loadAndDisplay(sig.$email)
        let p = try ctx.loadAndDisplay(sig.$password, secure: true)

        let api = UserApi()
        let _ = try api.signup(
            email: e,
            firstName: f,
            lastName: l,
            organizationName: o,
            password: p
        )
        ctx.console.output("success. welcome to cloud..".consoleText(.info))
    }
}

extension CommandContext {
    func loadAndDisplay<T: LosslessStringConvertible>(_ opt: Option<T>, secure: Bool = false) throws -> String {
        let val = opt.load(with: self, secure: secure).description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !val.isEmpty else { throw "no value entered for \(opt.name)" }
        display(opt, value: val, secure: secure)
        return val
    }

    func display<T: LosslessStringConvertible>(_ opt: Option<T>, value: String, secure: Bool) {
        console.output(opt.name.consoleText(.info), newLine: false)
        let text = secure ? "*****" : value.consoleText()
        console.output(": " + text)
    }
}
