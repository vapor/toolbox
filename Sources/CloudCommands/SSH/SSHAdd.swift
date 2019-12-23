import ConsoleKit
import Foundation
import Globals
import CloudAPI

struct SSHAdd: Command {
    struct Signature: CommandSignature {
        @Option(name: "readable-name", short: "n")
        var readableName: String?
        @Option(name: "path", short: "p")
        var path: String?
        @Option(name: "key", short: "k")
        var key: String?
    }
    
    let help = "add an ssh key to cloud."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let runner = try CloudSSHAddRunner(ctx: ctx, signature: signature)
        try runner.run()
    }
}

struct CloudSSHAddRunner {
    let ctx: CommandContext
    let signature: SSHAdd.Signature
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext, signature: SSHAdd.Signature) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token)
        self.ctx = ctx
        self.signature = signature
    }

    func run() throws {
        let k = try key()
        let n = name()
        ctx.console.output("pushing ssh key...")
        let created = try api.add(name: n, key: k)
        self.ctx.console.output("pushed key as \(created.name).".consoleText())
    }

    func name() -> String {
        return signature.$readableName.load(with: ctx, "give your key a readable name")
    }

    func key() throws -> String {
        guard let key = signature.key else { return try loadKey() }
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
        if let path = signature.path { return path }
        let allKeys = try Shell.bash("ls  ~/.ssh/*.pub")
        let separated = allKeys.split(separator: "\n").map(String.init)
        let term = Terminal()
        return term.choose("which key would you like to push?", from: separated)
    }
}
