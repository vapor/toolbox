import Foundation
import ConsoleKit
import CloudAPI
import Globals

public struct CloudGroup: ToolboxGroup {
    /// See `CommandGroup`.
    public var commands: [String : AnyCommand] = [
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
        "logs": Logs(),

        // RUN REMOTE COMMANDS
        "command": CloudRunCommand()
    ]
    
    /// See `CommandGroup`.
    public let help = "cloouuuddddd"
    
    /// Creates a new `BasicCommandGroup`.
    public init() {}
    
    /// See `CommandGroup`.
    public func fallback(using ctx: inout CommandContext) throws {
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
        @Option(name: "app", short: "a")
        var app: String
        @Option(name: "env", short: "e")
        var env: String
        @Option(name: "lines", short: "l")
        var lines: Int
        @Flag(name: "show-timestamps", short: "t")
        var showTimestamps: Bool
    }

    // help
    let help = "get logs for your application."
    
    func run(using ctx: CommandContext, signature: Signature) throws {
        let runner = try LogsRunner(ctx: ctx, signature: signature)
        return try runner.run()
    }
}

struct LogsRunner {
    let ctx: CommandContext
    let signature: Logs.Signature
    let token: Token

    init(ctx: CommandContext, signature: Logs.Signature) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        self.signature = signature
    }

    func run() throws {
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
        let timestamps = signature.showTimestamps
        let lines = self.signature.lines?.description ?? "200"
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

struct CloudRunCommand: Command {
    struct Signature: CommandSignature {
        @Option(name: "app", short: "a")
        var app: String
        @Option(name: "env", short: "e")
        var env: String
    }

    let help = "run commands on your cloud app."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let token = try Token.load()
        let app = try ctx.loadApp(with: token)
        let env = try ctx.loadEnv(for: app, with: token)
        let command = ctx.console.ask("enter command: ").trimmingCharacters(in: .whitespacesAndNewlines)
        let api = CloudRunCommandAPI(with: token)
        let result = try api.run(command: command, env: env.id)
        print("should now subscribe to ws for commmand id: \(result.id)")
        try result.listen(token: token) { (update) in
            switch update {
            case .connected:
                print("connected")
            case .message(let msg):
                print("got update: \(msg)")
            case .close:
                print("closed")
            }
        }
        print("all done")
    }
}

import AsyncWebSocketClient

extension CloudRunCommandObject {
    public enum Update {
        case connected
        case message(String)
        case close
    }

    public func listen(token: Token, _ listener: @escaping (Update) -> Void) throws {
        let raw = commandsWssUrl(id: id, token: token)
        let url = URL(string: raw)!
        print("connecting to: \(url)")
        let host = url.host!
        let uri = url.path + "?token=\(token.key)"
        print("h: \(host)\nuri: \(uri)")
        let client = WebSocketClient(eventLoopGroupProvider: .createNew)
        let connection = client.connect(host: host, port: 80, uri: uri, headers: [:]) { ws in
            listener(.connected)

            ws.onText { ws, text in
                listener(.message(text))
            }

            ws.onBinary { _, _ in
                fatalError("not prepared to accept binary")
            }

            ws.onCloseCode { _ in
                listener(.close)
                _ = ws.close()
            }
        }
        print("finished")
        try connection.wait()
        try client.syncShutdown()
    }
}
