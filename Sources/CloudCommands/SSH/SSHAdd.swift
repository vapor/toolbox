import Vapor
import Globals
import CloudAPI

struct SSHAdd: Command {
    struct Signature: CommandSignature {
        let readableName: Option = .readableName
        let path: Option = .path
        let key: Option = .key
    }
    
    let signature = Signature()
    
    let help: String? = "add an ssh key to cloud."

    func run(using ctx: Context) throws {
        let runner = try CloudSSHAddRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudSSHAddRunner<C: CommandRunnable> {
    let ctx: CommandContext<C>
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext<C>) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token)
        self.ctx = ctx
    }

    func run() throws {
        let k = try key()
        let n = name()
        ctx.console.output("pushing ssh key...")
        let created = try api.add(name: n, key: k)
        self.ctx.console.output("pushed key as \(created.name).".consoleText())
//        return created.map { created in
//        }
    }

    func name() -> String {
        return ctx.load(.readableName, "give your key a readable name")
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
        return term.choose("which key would you like to push?", from: separated)
    }
}
