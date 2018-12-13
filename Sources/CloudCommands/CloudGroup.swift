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
        return .done(on: ctx.container)
    }
}

struct Logs: Command {

    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app
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

    func run() throws -> Future<Void> {
        let app = try loadApp()
        let env = try loadEnv(for: app)
        return env.flatMap { env in
            let url = replicasUrl(with: env)
            let access = CloudReplica.Access(
                with: self.token,
                baseUrl: url,
                on: self.ctx.container
            )
            let replicas = access.list()
            return replicas.map { replicas in
                print("Got replicas: \(replicas)")
            }
        }
    }
}
