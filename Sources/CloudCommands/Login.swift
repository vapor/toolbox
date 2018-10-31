import Vapor
import CloudAPI

struct CloudLogin: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
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
        )
    ]

    /// See `Command`.
    var help: [String] = ["Logs into Vapor Cloud"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = CloudLoginRunner(ctx: ctx)
        return runner.run()
    }
}

struct CloudLoginRunner {
    let ctx: CommandContext

    func run() -> Future<Void> {
        let e = email()
        let p = password()
        let token = UserApi(on: ctx.container).login(email: e, password: p)
        return token.map {
            try $0.save()
            self.ctx.console.output("Cloud is Ready".consoleText(.info))
        }
    }

    func email() -> String {
        if let email = ctx.options["email"] { return email }
        return ctx.console.ask("email")
    }

    func password() -> String {
        if let pass = ctx.options["password"] { return pass }
        return ctx.console.ask("password", isSecure: true)
    }
}

//struct Me: MyCommand {
//    /// See `Command`.
//    var arguments: [CommandArgument] = []
//
//    /// See `Command`.
//    var options: [CommandOption] = [
//        .flag(
//            name: "all",
//            short: "a",
//            help: ["include more data about user"]
//        ),
//    ]
//
//    /// See `Command`.
//    var help: [String] = ["Shows information about user."]
//
//    /// See `Command`.
//    func trigger(with ctx: CommandContext) throws {
//        let token = try Token.load()
//        let me = try UserApi.me(token: token)
//        ctx.console.output("Email:")
//        ctx.console.output(me.email.consoleText())
//        ctx.console.output("Name:")
//        let name = me.firstName + " " + me.lastName
//        ctx.console.output(name.consoleText())
//
//        let all = ctx.options["all"]?.bool == true
//        guard all else { return }
//        ctx.console.output("ID:")
//        ctx.console.output(me.id.uuidString.consoleText())
//    }
//}
//
//struct DumpToken: MyCommand {
//    /// See `Command`.
//    var arguments: [CommandArgument] = []
//
//    /// See `Command`.
//    var options: [CommandOption] = []
//
//    /// See `Command`.
//    var help: [String] = ["Dump token data"]
//
//    /// See `Command`.
//    func trigger(with ctx: CommandContext) throws {
//        let token = try Token.load()
//        ctx.console.output("Expires At:")
//        ctx.console.output(token.expiresAt.description.consoleText())
//        ctx.console.output("UserID:")
//        ctx.console.output(token.userID.uuidString.description.consoleText())
//        ctx.console.output("ID:")
//        ctx.console.output(token.id.uuidString.consoleText())
//        ctx.console.output("Token:")
//        ctx.console.output(token.token.consoleText())
//    }
//}
//

extension Token {
    var isValid: Bool {
        return !isExpired
    }
    var isExpired: Bool {
        return expiresAt < Date()
    }
}

extension Token {
    static func filePath() throws -> String {
        let home = try Shell.homeDirectory()
        return home.finished(with: "/") + ".vapor/token"
    }

    static func load() throws -> Token {
        let path = try filePath()
        let exists = FileManager
            .default
            .fileExists(atPath: path)
        guard exists else { throw "not logged in, use 'vapor cloud login', and try again." }
        let loaded = try FileManager.default.contents(atPath: path).flatMap {
            try JSONDecoder().decode(Token.self, from: $0)
        }
        guard let token = loaded else {
            throw "error, use 'vapor cloud login', and try again."
        }
        guard token.isValid else {
            throw "expired credentials, use 'vapor cloud login', and try again."
        }
        return token
    }

    func save() throws {
        let path = try Token.filePath()
        let data = try JSONEncoder().encode(self)
        let create = FileManager.default.createFile(
            atPath: path, contents: data, attributes: nil
        )
        guard create else { throw "there was a problem svaing the token." }
    }
}

import Vapor

//extension String: Error {}

struct Shell {
    @discardableResult
    static func bash(_ input: String) throws -> String {
        return try Process.execute("/bin/sh", "-c", input)
    }

    static func delete(_ path: String) throws {
        try bash("rm -rf \(path)")
    }

    static func cwd() throws -> String {
        return try Environment.get("TEST_DIRECTORY") ?? bash("dirs -l")
    }

    static func allFiles(in dir: String? = nil) throws -> String {
        var command = "ls -lah"
        if let dir = dir {
            command += " \(dir)"
        }
        return try Shell.bash(command)
    }

    static func readFile(path: String) throws -> String {
        return try bash("cat \(path)").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func homeDirectory() throws -> String {
        return try bash("echo $HOME").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

