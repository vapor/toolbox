import Vapor

struct CloudSSHPush: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "path", short: "p", default: nil, help: ["a custom path to they public key that should be pushed"]),
        .value(name: "name", short: "n", default: nil, help: ["the readable name to give your key"]),
        .value(name: "key", short: "k", default: nil, help: ["use this to pass the contents of your public key directly"])
    ]

    /// See `Command`.
    var help: [String] = ["Logs into Vapor Cloud"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = try CloudSSHPushRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudSSHPushRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        guard let token = try Token.load() else {
            throw "not logged in, use 'vapor cloud login', and try again."
        }

        self.token = token
        self.api = SSHKeyApi(token: token)
        self.ctx = ctx
    }

    func run() throws {
        let n = name()
        let k = try key()
        let _ = try api.push(name: n, key: k)
    }

    func name() -> String {
        if let name = ctx.options["name"] { return name }
        return ctx.console.ask("name")
    }

    func key() throws -> String {
        guard let key = ctx.options["key"] else { return try loadKey() }
        return key
    }

    func loadKey() throws -> String {
        let p = try path()
        guard FileManager.default.fileExists(atPath: p) else { throw "no rsa key found at \(p)" }
        guard let file = FileManager.default.contents(atPath: p) else { throw "unable to load rsa key" }
        guard let key = String(data: file, encoding: .utf8) else { throw "no string found in data" }
        return key
    }

    func path() throws -> String {
        if let path = ctx.options["path"] { return path }
        let allKeys = try Shell.bash("ls  ~/.ssh/*.pub")
        let separated = allKeys.split(separator: "\n").map(String.init)
        let term = Terminal()
        return term.choose("Which key would you like to push?", from: separated)
    }
}
