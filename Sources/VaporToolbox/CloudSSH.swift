import Vapor

struct CloudSSHGroup: CommandGroup {
    /// See `CommandGroup`.
    var commands: Commands = [
        "push" : CloudSSHPush(),
        "list": CloudSSHList(),
        "delete": CloudSSHDelete(),
    ]

    /// See `CommandGroup`.
    var options: [CommandOption] {
        return []
    }

    /// See `CommandGroup`.
    var help: [String] = [
        "Use this to interact with, list, push, and delete SSH keys on Vapor Cloud"
    ]

    /// See `CommandGroup`.
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        // should never run
        throw "should not run"
    }
}

struct CloudSSHPush: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "name", short: "n", default: nil, help: ["the readable name to give your key"]),
        .value(name: "path", short: "p", default: nil, help: ["a custom path to they public key that should be pushed"]),
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
        self.token = try Token.load()
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

struct CloudSSHList: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "long", short: "l", default: nil, help: ["Include the full key in logout"])
    ]

    /// See `Command`.
    var help: [String] = ["Lists the SSH keys that you have pushed to cloud"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = try CloudSSHListRunner(ctx: ctx)
        try runner.run()
    }


}

struct CloudSSHListRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(token: token)
        self.ctx = ctx
    }

    func run() throws {
        let list = try api.list()
        log(list)
    }

    func log(_ list: [SSHKey]) {
        let long = ctx.options["long"]?.bool == true
        let console = ctx.console
        list.forEach { key in
            // Insert line of space for each key
            defer { console.output("") }
            console.output("Name:")
            console.output(key.name.consoleText())
            console.output("Created At:")
            // TODO: Format to local timezone
            console.output(key.createdAt.description.consoleText())

            guard long else { return }
            console.output("Key:")
            console.output(key.key.consoleText())
        }
    }
}

struct CloudSSHDelete: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Lists the SSH keys that you have pushed to cloud"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = try CloudSSHDeleteRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudSSHDeleteRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(token: token)
        self.ctx = ctx
    }

    func run() throws {
        let list = try api.list()
        let choice = ctx.console.choose("Which Key?", from: list) { key in
            return "\(key.name) : \(key.createdAt)".consoleText()
        }
        try api.delete(choice)
    }
}
