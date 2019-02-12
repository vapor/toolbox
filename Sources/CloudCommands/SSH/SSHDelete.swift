import Vapor
import CloudAPI

struct SSHDelete: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Delete an SSH Key."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try SSHDeleteRunner(ctx: ctx)
        return runner.run()
    }
}

struct SSHDeleteRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token, on: ctx.container)
        self.ctx = ctx
    }

    func run() -> Future<Void> {
        let list = api.list()
        return list.flatMap { list in
            guard !list.isEmpty else {
                self.ctx.console.output("No SSH keys found. Nothing to delete.")
                return Future.done(on: self.ctx.container)
            }

            let choice = self.ctx.console.choose("Which Key?", from: list) { key in
                return "\(key.name) : \(key.createdAt)".consoleText()
            }
            return self.api.delete(choice)
        }
    }
}
