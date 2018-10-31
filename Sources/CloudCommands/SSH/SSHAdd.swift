import Vapor
import CloudAPI

extension CommandOption {
    static let readableName: CommandOption = .value(
        name: "readable-name",
        short: "n",
        default: nil,
        help: ["The readable name to give your key."]
    )
    static let path: CommandOption = .value(
        name: "path",
        short: "p",
        default: nil,
        help: ["A custom path to they public key that should be pushed."]
    )
    static let key: CommandOption = .value(
        name: "key",
        short: "k",
        default: nil,
        help: ["Use this to pass the contents of your public key directly."]
    )
}

struct SSHAdd: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .readableName,
        .path,
        .key,
    ]

    /// See `Command`.
    var help: [String] = ["Add an SSH key to cloud."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try CloudSSHPushRunner(ctx: ctx)
        return try runner.run()
    }
}

struct CloudSSHPushRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token, on: ctx.container)
        self.ctx = ctx
    }

    func run() throws -> Future<Void> {
        let k = try key()
        let n = name()
        ctx.console.output("Pushing SSH key...")
        let created = api.add(name: n, key: k)
        return created.map { created in
            self.ctx.console.output("Pushed key as \(created.name).".consoleText())
        }
    }

    func name() -> String {
        return ctx.load(.readableName, "Give your key a readable name")
    }

    func key() throws -> String {
        guard let key = ctx.options.value(.key) else { return try loadKey() }
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
        if let path = ctx.options.value(.path) { return path }
        let allKeys = try Shell.bash("ls  ~/.ssh/*.pub")
        let separated = allKeys.split(separator: "\n").map(String.init)
        let term = Terminal()
        return term.choose("Which key would you like to push?", from: separated)
    }
}
