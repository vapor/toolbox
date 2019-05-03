import ConsoleKit
import CloudAPI
import Globals

struct SSHList: Command {
    struct Signature: CommandSignature {
        let all: Option = .all
    }
    
    let signature = Signature()
    
    let help: String? = "lists the ssh keys that you have pushed to cloud."

    func run(using ctx: Context) throws {
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
