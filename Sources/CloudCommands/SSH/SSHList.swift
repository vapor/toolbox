import ConsoleKit
import CloudAPI
import Globals

struct SSHList: Command {
    struct Signature: CommandSignature {
        let all: Option = .all
    }
    
    let signature = Signature()
    
    let help: String = "lists the ssh keys that you have pushed to cloud."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let runner = try CloudSSHListRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudSSHListRunner<C: CommandRunnable> {
    let ctx: CommandContext<C>
    let token: Token
    let api: SSHKeyApi

    init(ctx: CommandContext<C>) throws {
        self.token = try Token.load()
        self.api = SSHKeyApi(with: token)
        self.ctx = ctx
    }

    func run() throws {
        let list = try api.list()
        log(list)
    }

    func log(_ list: [SSHKey]) {
        let long = ctx.flag(.all)
        if list.isEmpty {
            ctx.console.output("no SSH keys found. nothing to show.")
        }

        list.forEach { key in
            // Insert line of space for each key
            defer { ctx.console.output("") }

            // Basic Key Log
            ctx.console.output("name: ", newLine: false)
            ctx.console.output(key.name.consoleText())
            ctx.console.output("created at: ", newLine: false)
            ctx.console.output(key.createdAt.consoleText())

            // Long Version
            guard long else { return }
            ctx.console.output("key: ")
            ctx.console.output(key.key.consoleText())
        }
    }
}
