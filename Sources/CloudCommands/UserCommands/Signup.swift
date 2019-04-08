import Vapor
import CloudAPI
import Globals

struct CloudSignup: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .firstName,
        .lastName,
        .org,
        .email,
        .password,
    ]

    /// See `Command`.
    var help: [String] = ["Creates a new account for Vapor Cloud."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let f = try ctx.loadAndDisplay(.firstName)
        let l = try ctx.loadAndDisplay(.lastName)
        let o = try ctx.loadAndDisplay(.org)
        let e = try ctx.loadAndDisplay(.email)
        let p = try ctx.loadAndDisplay(.password, secure: true)

        todo()
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
    func loadAndDisplay(_ opt: CommandOption, secure: Bool = false) throws -> String {
        let val = load(opt, secure: secure).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !val.isEmpty else { throw "No value entered for \(opt.name)" }
        display(opt, value: val, secure: secure)
        return val
    }

    func display(_ opt: CommandOption, value: String, secure: Bool) {
        console.output(opt.name.consoleText(.info), newLine: false)
        let text = secure ? "*****" : value.consoleText()
        console.output(": " + text)
    }
}
