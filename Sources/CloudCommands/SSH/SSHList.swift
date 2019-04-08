import Vapor
import CloudAPI
import Globals

struct SSHList: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .all
    ]

    /// See `Command`.
    var help: [String] = ["Lists the SSH keys that you have pushed to cloud"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try CloudSSHListRunner(ctx: ctx)
        return runner.run()
    }
}

struct CloudSSHListRunner {
    let ctx: CommandContext
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext) throws {
        self.token = try Token.load()
        todo()
//        self.api = SSHKeyApi(with: token, on: ctx.container)
        self.ctx = ctx
    }

    func run() -> EventLoopFuture<Void> {
        let list = api.list()
        return list.map {
            self.log($0)
        }
    }

    func log(_ list: [SSHKey]) {
        let long = ctx.flag(.all)
        if list.isEmpty {
            ctx.console.output("No SSH keys found. Nothing to show.")
        }

        list.forEach { key in
            // Insert line of space for each key
            defer { ctx.console.output("") }

            // Basic Key Log
            ctx.console.output("Name: ", newLine: false)
            ctx.console.output(key.name.consoleText())
            ctx.console.output("Created At: ", newLine: false)
            ctx.console.output(key.createdAt.description.consoleText())

            // Long Version
            guard long else { return }
            ctx.console.output("Key: ")
            ctx.console.output(key.key.consoleText())
        }
    }
}
