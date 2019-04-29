import Vapor
import CloudAPI
import Globals

struct SSHDelete: Command {
    struct Signature: CommandSignature {}
    
    /// See `Command`.
    let signature = Signature()
    
    let help: String? = "delete an ssh key from vapor cloud."

    /// See `Command`.
    func run(using ctx: Context) throws {
        let runner = try SSHDeleteRunner(ctx: ctx.any)
        try runner.run()
    }
}

struct AnyContext {
    let console: Console
    init<C>(ctx: CommandContext<C>) {
        self.console = ctx.console
    }
}

extension CommandContext {
    var any: AnyContext { return .init(ctx: self) }
}

struct SSHDeleteRunner {
    let ctx: AnyContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: AnyContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token)
        self.ctx = ctx
    }

    func run() throws {
        let list = try api.list()//.wait()
        guard !list.isEmpty else {
            self.ctx.console.output("No SSH keys found. Nothing to delete.")
            return
        }
        
        let choice = self.ctx.console.choose("Which Key?", from: list) { key in
            return "\(key.name) : \(key.createdAt)".consoleText()
        }
        
        try self.api.delete(choice)//.wait()
    }
    
//    func run() -> EventLoopFuture<Void> {
//        let list = api.list()
//        return list.flatMap { list in
//            guard !list.isEmpty else {
//                self.ctx.console.output("No SSH keys found. Nothing to delete.")
//                return self.ctx.done
//            }
//
//            let choice = self.ctx.console.choose("Which Key?", from: list) { key in
//                return "\(key.name) : \(key.createdAt)".consoleText()
//            }
//            return self.api.delete(choice)
//        }
//    }
}
