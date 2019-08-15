import Foundation
import ConsoleKit
import CloudAPI
import Globals

public struct CloudGroup: CommandGroup {
    /// See `CommandRunnable`.
    public struct Signature: CommandSignature { }
    
    /// See `CommandRunnable`.
    public let signature = Signature()
    
    /// See `CommandGroup`.
    public var commands: Commands = [
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
    
    /// See `CommandGroup`.
    public var help = "cloouuuddddd"
    
    /// Creates a new `BasicCommandGroup`.
    public init() {}
    
    /// See `CommandGroup`.
    public func run(using ctx: CommandContext<CloudGroup>) throws {
        ctx.console.info("welcome to cloud.")
        ctx.console.output("use `vapor cloud -h` to see commands.")
        let cloud = [
            "   _  _         ",
            "  ( `   )_      ",
            " (    )    `)   ",
            "(_   (_ .  _) _)",
            "                ",
        ]
        let centered = ctx.console.center(cloud)
        centered.map { $0.consoleText() } .forEach(ctx.console.output)
    }
}

struct Logs: Command {
    // definition
    struct Signature: CommandSignature {
        let app: Option = .app
        let env: Option = .env
        let lines: Option = .lines
        let timestamps: Option = .showTimestamps
    }
    
    // signature
    let signature = Signature()
    
    // help
    let help = "get logs for your application."
    
    func run(using ctx: Context) throws {
        let runner = try LogsRunner(ctx: ctx)
        return try runner.run()
    }
}

struct LogsRunner<C: CommandRunnable> {//}: AuthorizedRunner {
    let ctx: CommandContext<C>
    let token: Token

    init(ctx: CommandContext<C>) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
    }

    func run() throws { // -> EventLoopFuture<Void> {
        let app = try ctx.loadApp(with: token)
        let env = try ctx.loadEnv(for: app, with: token)
        let url = replicasUrl(with: env)
        let access = CloudReplica.Access(
            with: self.token,
            baseUrl: url
        )
        let list = try access.list()
        let replicas = list.filter { $0.slug == "web" }
        guard replicas.count == 1 else { throw "there should only ever be a single web type replica" }
        let web = replicas[0]
        
        let logsEndpoint = logsUrl(with: web)
        let logs = CloudLogs.Access(with: self.token, baseUrl: logsEndpoint)
        
        // query
        // lines -- default 200
        // pod -- a specific pod
        // timestamps -- whether to include timestamps
        let timestamps = self.ctx.flag(.showTimestamps)
        let lines = self.ctx.rawOptions.value(.lines) ?? "200"
        let query = "lines=\(lines)&timestamps=\(timestamps.description)"
        let entries = try logs.list(query: query)
        for log in entries {
            self.ctx.console.output("pod: ", newLine: false)
            self.ctx.console.output(log.name.consoleText(.info))
            let output = log.logs + "\n"
            self.ctx.console.output(output.consoleText())
        }
    }
}
