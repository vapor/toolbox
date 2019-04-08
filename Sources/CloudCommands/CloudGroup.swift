import Vapor
import CloudAPI
import Globals

public struct CloudGroup: CommandGroup {
    public let commands: Commands = [
        // USER COMMANDS
        "login": CloudLogin(),
        "signup": CloudSignup(),
        "me": Me(),
        "reset-password": ResetPassword(),

        // DIAGNOSTICS
        "dump-token": DumpToken(),

        // SSH
        "ssh": SSHGroup(),

        // DEPLOY
        "deploy": CloudDeploy(),

        // Push
        "push": CloudPush(),

        // REMOTE
        "remote": RemoteGroup(),

        // LOGS
        "logs": Logs()
    ]

    public let options: [CommandOption] = []

    /// See `CommandGroup`.
    public var help: [String] = [
        "Interact with Vapor Cloud."
    ]

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        ctx.console.info("Welcome to Cloud.")
        ctx.console.output("Use `vapor cloud -h` to see commands.")
        let cloud = [
            "   _  _         ",
            "  ( `   )_      ",
            " (    )    `)   ",
            "(_   (_ .  _) _)",
            "                ",
        ]
        let centered = ctx.console.center(cloud)
        centered.map { $0.consoleText() } .forEach(ctx.console.output)
        return ctx.done
    }
}

struct Logs: Command {

    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app,
        .env,
        .lines,
        .showTimestamps,
    ]

    /// See `Command`.
    var help: [String] = [
        "get logs for your application."
    ]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try LogsRunner(ctx: ctx)
        return try runner.run()
    }
}

struct LogsRunner: AuthorizedRunner {
    let ctx: CommandContext
    let token: Token

    init(ctx: CommandContext) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
    }

    func run() throws -> EventLoopFuture<Void> {
        let app = try loadApp()
        let env = try loadEnv(for: app)
        return env.flatMap { env in
            let url = replicasUrl(with: env)
            let access: ResourceAccess<CloudReplica>! = { todo() }()
//            let access = CloudReplica.Access(
//                with: self.token,
//                baseUrl: url,
//                on: self.ctx.container
//            )
            let replicas = access.list()
            return replicas.flatMap { replicas in
                let replicas = replicas.filter { $0.slug == "web" }
                guard replicas.count == 1 else {
                    return self.ctx.eventLoop.makeFailedFuture("there should only ever be a single web type replica")
                }
                let web = replicas[0]

                let logsEndpoint = logsUrl(with: web)
                let logs: ResourceAccess<CloudLogs>! = { todo() }()
//                let logs = CloudLogs.Access(with: self.token, baseUrl: logsEndpoint, on: self.ctx.container)
                
                // query
                // lines -- default 200
                // pod -- a specific pod
                // timestamps -- whether to include timestamps
                let timestamps = self.ctx.flag(.showTimestamps)
                let lines = self.ctx.options.value(.lines) ?? "200"
                let query = "lines=\(lines)&timestamps=\(timestamps.description)"
                let list = logs.list(query: query)
                return list.map { list in
                    for log in list {
                        self.ctx.console.output("pod: ", newLine: false)
                        self.ctx.console.output(log.name.consoleText(.info))
                        let output = log.logs + "\n"
                        self.ctx.console.output(output.consoleText())
                    }
                }
            }
        }
    }
}
