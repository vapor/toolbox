import Vapor
import CloudAPI

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
        let f = ctx.loadAndDisplay(.firstName)
        let l = ctx.loadAndDisplay(.lastName)
        let o = ctx.loadAndDisplay(.org)
        let e = ctx.loadAndDisplay(.email)
        let p = ctx.loadAndDisplay(.password)

        let api = UserApi(on: ctx.container)
        let user = api.signup(
            email: e,
            firstName: f,
            lastName: l,
            organizationName: o,
            password: p
        )
        return user.map { _ in
            ctx.console.output("Welcome to Cloud".consoleText(.info))
        }
    }
}

extension CommandContext {
    func loadAndDisplay(_ opt: CommandOption) -> String {
        let val = load(opt)
        display(.firstName, value: val)
        return val
    }

    func display(_ opt: CommandOption, value: String) {
        console.output(opt.name.consoleText(.info), newLine: false)
        console.output(": " + value.consoleText())
    }
}
