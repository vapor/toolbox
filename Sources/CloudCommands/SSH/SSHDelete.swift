import ConsoleKit
import CloudAPI
import Globals

struct SSHDelete: Command {
    struct Signature: CommandSignature {}
    
    let help: String = "delete an ssh key from vapor cloud."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let runner = try SSHDeleteRunner(ctx: ctx)
        try runner.run()
    }
}

struct SSHDeleteRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token)
        self.ctx = ctx
    }

    func run() throws {
        let list = try api.list()//.wait()
        guard !list.isEmpty else {
            self.ctx.console.output("no ssh keys found. nothing to delete.")
            return
        }
        
        let choice = self.ctx.console.choose("which key?", from: list) { key in
            return "\(key.name) : \(key.createdAt)".consoleText()
        }
        
        try self.api.delete(choice)//.wait()
    }
}
