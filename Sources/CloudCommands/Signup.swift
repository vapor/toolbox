import Vapor
import CloudAPI

struct CloudSignup: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(
            name: "first",
            short: "f",
            default: nil,
            help: ["the first name of the user to sign up"]
        ),
        .value(
            name: "last",
            short: "l",
            default: nil,
            help: ["the last name of the user to sign up"]
        ),
        .value(
            name: "org",
            short: "o",
            default: nil,
            help: ["the name of your organization"]
        ),
        .value(
            name: "email",
            short: "e",
            default: nil,
            help: ["the email to use when logging in"]
        ),
        .value(
            name: "password",
            short: "p",
            default: nil,
            help: ["the password to use when logging in"]
        ),
    ]

    /// See `Command`.
    var help: [String] = ["Creates a new account for Vapor Cloud."]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = CloudSignupRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudSignupRunner {
    let ctx: CommandContext

    func run() throws {
        let f = firstName()
        let l = lastName()
        let o = organization()
        let e = email()
        let p = try password()
        let _ = try UserApi.signup(
            email: e,
            firstName: f,
            lastName: l,
            organizationName: o,
            password: p
        )
        ctx.console.output("Welcome to Cloud".consoleText(.info))
    }

    func email() -> String {
        if let email = ctx.options["email"] { return email }
        return ctx.console.ask("Email")
    }

    func password() throws -> String {
        if let pass = ctx.options["password"] { return pass }
        let one = ctx.console.ask("Password", isSecure: true)
        let two = ctx.console.ask("Confirm Password", isSecure: true)
        guard one == two else { throw "Passwords did not match." }
        return one
    }

    func firstName() -> String {
        if let first = ctx.options["first"] { return first }
        return ctx.console.ask("First Name")
    }

    func lastName() -> String {
        if let first = ctx.options["last"] { return first }
        return ctx.console.ask("Last Name")
    }

    func organization() -> String {
        if let first = ctx.options["org"] { return first }
        return ctx.console.ask("Organization (i.e. My Org)")
    }
}

