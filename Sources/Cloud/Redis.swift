import Redis
import Node
import JSON
import Core
import Foundation
import libc
import Sockets
import CloudClients

public enum UpdateType: String, NodeInitializable {
    case start, stop

    public init(node: Node) throws {
        guard
            let string = node.string,
            let new = UpdateType(rawValue: string)
            else {
                throw NodeError.unableToConvert(input: node, expectation: "String", path: [])
            }
        self = new
    }
}

public struct Update: NodeInitializable {
    public let message: String
    public let success: Bool
    public let type: UpdateType
    public let isLast: Bool

    public init(node: Node) throws {
        message = try node.get("message")
        success = try node.get("success")
        type = try node.get("type")
        isLast = try node.get("ended")
    }
}

public struct DatabaseInfo: NodeInitializable {
    public let hostname: String
    public let port: String
    public let environmentId: String
    public let username: String
    public let password: String
    public let ended: Bool
    public let type: String
    public let token: String
    
    public init(node: Node) throws {
        hostname = try node.get("hostname") ?? ""
        port = try node.get("port") ?? ""
        environmentId = try node.get("environmentId") ?? ""
        username = try node.get("username") ?? ""
        password = try node.get("password") ?? ""
        type = try node.get("type") ?? ""
        token = try node.get("token") ?? ""
        ended = try node.get("ended") ?? false
    }
}

public struct DatabaseListObj: NodeInitializable {
    public let name: String
    public let port: String
    public let status: String
    public let type: String
    public let version: String
    public let host: String
    public let token: String
    public let size: String
    public let ended: Bool
    
    public init(node: Node) throws {
        name = try node.get("name") ?? ""
        port = try node.get("port") ?? ""
        status = try node.get("status") ?? ""
        type = try node.get("type") ?? ""
        version = try node.get("version") ?? ""
        host = try node.get("host") ?? ""
        token = try node.get("token") ?? ""
        size = try node.get("size") ?? ""
        ended = try node.get("ended") ?? false
    }
}

public struct FeedbackInfo: NodeInitializable {
    public let status: String
    public let message: String
    public let finished: Bool
    
    public init(node: Node) throws {
        status = try node.get("status")
        message = try node.get("message")
        finished = try node.get("finished") ?? false
    }
}
extension Client where StreamType == TCPInternetSocket {
    static func cloudRedis() throws -> TCPClient {
        return try .init(
            hostname: "redis.eu.vapor.cloud",
            port: 6379,
            password: nil
        )
    }
}

public final class CloudRedis {
    static func subscribeDeployLog(id: String, _ updater: @escaping (Update) throws -> Void) throws {
        _ = try Portal<Bool>.open { portal in
            let client = try TCPClient.cloudRedis()
            let deployLog = "deployLog_\(id)"
            try client.subscribe(channel: deployLog) { data in
                do {
                    guard let data = data else { return }
                    let json = data.array?
                        .flatMap { $0?.bytes }
                        .last
                        .flatMap { try? JSON(bytes: $0) }
                    let update = try Update(node: json)
                    try updater(update)
                    guard update.isLast || !update.success else { return }
                    portal.close(with: true)
                } catch {
                    portal.close(with: error)
                }
            }
        }
    }

    static func tailLogs(
        console: ConsoleProtocol,
        repo: String,
        envName: String,
        since: String
    ) throws {

        // the channel we want logs posted to
        let listenChannel = UUID().uuidString
        // the replica to listen to
        let replicaController = "\(repo)-\(envName)"

        var message = JSON([:])
        // app request
        try message.set("channel", listenChannel)
        try message.set("rc", replicaController)
        /*
         `5s` = 5 seconds
         `5m` = 5 minutes
         `5h` = 5 hours
         */
        try message.set("since", since)
        
        let cache = try TokenCache.global(with: console)
        try message.set("token", cache.getAccessToken()?.makeString())

        var start = message
        try start.set("status", "start")

        var exit = message
        try exit.set("status", "exit")

        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "requestLog", start)
        console.registerKillListener { _ in
            _ = try? pubClient.publish(channel: "requestLog", exit)
        }

        let listenClient = try TCPClient.cloudRedis()
        try listenClient.subscribe(channel: listenChannel) { (data) in
            guard let log = data?
                .array?
                .flatMap({ $0?.bytes })
                .last?
                .split(separator: .space, maxSplits: 1)
                .last?
                .makeString()
                else { return }

            console.print(log)
        }
    }

    static func betaQueue(
        console: ConsoleProtocol,
        email: String,
        motivation: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("email", email)
        try message.set("motivation", motivation)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "betaQueue", message)

        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
        
        console.info("")
        console.success("You are now in the Beta queue. You will receive an Email once your are approved.")
    }
    
    static func createDBServer(
        console: ConsoleProtocol,
        cloudFactory: CloudAPIFactory,
        application: String,
        name: String,
        size: String,
        engine: String,
        engineVersion: String,
        environments: [String],
        userToken: String,
        email: String
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("application", application)
        try message.set("name", name)
        try message.set("size", size)
        try message.set("engine", engine)
        try message.set("engineVersion", engineVersion)
        try message.set("environments", environments)
        try message.set("userToken", userToken)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "createDatabaseServer", message)
        
        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
        
        let logsBar = console.loadingBar(title: "Creating configuration variables")
        logsBar.start()
        
        let listenInfoClient = try TCPClient.cloudRedis()
        try listenInfoClient.subscribe(channel: listenChannel + "_Info") { data in
            do {
                guard let data = data else { return }
                let json = data.array?
                    .flatMap { $0?.bytes }
                    .last
                    .flatMap { try? JSON(bytes: $0) }
        
                let dbInfo = try DatabaseInfo(node: json)
                
                if (dbInfo.ended) {
                    logsBar.finish()
                    
                    console.info("")
                    console.success("Make sure to setup \"$\(dbInfo.token)\" in your database config file")
                    console.warning("For now you need to redeploy your application, for it to use the new database server")
                }
                
                _ = try ShowDatabaseInfo(console, cloudFactory)
                    .createConfig(dbInfo: dbInfo, application: application)
            } catch {
                
            }
        }
    }
    
    static func dbServerLog(
        console: ConsoleProtocol,
        name: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("name", name)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "databaseLog", message)
        
        let listenClient = try TCPClient.cloudRedis()
        try listenClient.subscribe(channel: listenChannel) { ( data) in
            guard
                let log = data?
                    .array?
                    .flatMap({ $0?.bytes })
                    .last?
                    .makeString()
                else { return }
            
            guard log != "EXIT!" else {
                do {
                    exit(0)
                } catch {
                    exit(1)
                }
            }
            
            console.print(log)
        }
    }
    
    static func shutdownDBServer(
        console: ConsoleProtocol,
        application: String,
        token: String,
        email: String
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("application", application)
        try message.set("token", token)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "shutdownDatabaseServer", message)

        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func resizeDBServer(
        console: ConsoleProtocol,
        application: String,
        token: String,
        email: String,
        newSize: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("application", application)
        try message.set("token", token)
        try message.set("email", email)
        try message.set("newSize", newSize)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "resizeDatabaseServer", message)
        
       try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func restartReplicas(
        console: ConsoleProtocol,
        repoName: String,
        environmentName: String,
        token: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("repoName", repoName)
        try message.set("environmentName", environmentName)
        try message.set("token", token)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "restartReplicas", message)
        
        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func subscribeLog(channel: String, _ feedback: @escaping (FeedbackInfo) throws -> Void) throws {
        _ = try Portal<Bool>.open { portal in
            let client = try TCPClient.cloudRedis()
            try client.subscribe(channel: channel) { data in
                do {
                    guard let data = data else { return }
                    let json = data.array?
                        .flatMap { $0?.bytes }
                        .last
                        .flatMap { try? JSON(bytes: $0) }
                    let log = try FeedbackInfo(node: json)
                    try feedback(log)

                    guard log.finished else { return }
                    portal.close(with: true)
                } catch {
                    portal.close(with: error)
                }
            }
        }
    }
    
    static func dbServerTokens(
        console: ConsoleProtocol,
        application: String,
        channel: String
        ) throws {
        
        var message = JSON([:])
        try message.set("channel", channel)
        try message.set("application", application)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "getTokenList", message)
        
        //try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func deleteDBServer(
        console: ConsoleProtocol,
        application: String,
        token: String,
        email: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("application", application)
        try message.set("token", token)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "DeleteDatabaseServer", message)

        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func restartDBServer(
        console: ConsoleProtocol,
        application: String,
        token: String,
        email: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("application", application)
        try message.set("token", token)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "RestartDatabaseServer", message)

        try  DatabaseLogSubscribe(console).subscribe(channel: listenChannel)
    }
    
    static func getDatabaseInfo(
        console: ConsoleProtocol,
        cloudFactory: CloudAPIFactory,
        environment: String? = "",
        environmentArr: [String?] = [],
        application: String? = "",
        token: String,
        email: String
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("environment", environment ?? "")
        try message.set("environmentArr", environmentArr)
        try message.set("token", token)
        try message.set("channel", listenChannel)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "getDatabaseInfo", message)
        
        let logsBar = console.loadingBar(title: "Contacting Database Master")
        logsBar.start()
        
        let listenClient = try TCPClient.cloudRedis()
        try listenClient.subscribe(channel: listenChannel) { data in
            do {
                logsBar.finish()
                guard let data = data else { return }
                let json = data.array?
                    .flatMap { $0?.bytes }
                    .last
                    .flatMap { try? JSON(bytes: $0) }
                
                let dbInfo = try DatabaseInfo(node: json)
                
                if (environment == "") {
                    _ = try ShowDatabaseInfo(console, cloudFactory)
                        .showInfo(dbInfo: dbInfo, application: application)
                } else {
                    try ShowDatabaseInfo(console, cloudFactory).login(dbInfo: dbInfo)
                }
            } catch {
                
            }
        }
    }
    
    static func getDatabaseList(
        console: ConsoleProtocol,
        cloudFactory: CloudAPIFactory,
        application: String,
        email: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("application", application)
        try message.set("channel", listenChannel)
        try message.set("email", email)
        
        // Publish start and kill exit
        let pubClient = try TCPClient.cloudRedis()
        try pubClient.publish(channel: "getDatabaseList", message)
       
        let logsBar = console.loadingBar(title: "Contacting Database Master")
        logsBar.start()
        
        let listenClient = try TCPClient.cloudRedis()
        try listenClient.subscribe(channel: listenChannel) { data in
            do {
                logsBar.finish()

                guard let data = data else { return }
                let json = data.array?
                    .flatMap { $0?.bytes }
                    .last
                    .flatMap { try? JSON(bytes: $0) }
                
                let dbInfo = try DatabaseListObj(node: json)
                
                    _ = try ShowDatabaseInfo(console, cloudFactory)
                        .listServers(dbInfo: dbInfo, application: application)
            } catch {
                
            }
        }
    }

    static func runCommand(
        console: ConsoleProtocol,
        command: String,
        repo: String,
        envName: String,
        with token: AccessToken
    ) throws {
        let listenChannel = UUID().uuidString
        let replicaController = repo + "-" + envName

        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("rc", replicaController)
        try message.set("command", command)
        try message.set("environment", envName)

        var start = message
        try start.set("status", "start")

        var stop = message
        try stop.set("status", "exit")

        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "redis.eu.vapor.cloud", port: 6379, password: nil)
        try pubClient.publish(channel: "runCommand", start)
        console.registerKillListener { _ in
            _ = try? pubClient.publish(channel: "runCommand", stop)
        }

        let listenClient = try TCPClient(hostname: "redis.eu.vapor.cloud", port: 6379, password: nil)
        try listenClient.subscribe(channel: listenChannel) { ( data) in
            guard
                let log = data?
                    .array?
                    .flatMap({ $0?.bytes })
                    .last?
                    .split(separator: .space, maxSplits: 1)
                    .last?
                    .makeString()
                else { return }

            guard log != "EXIT!" else {
                do {
                    _ = try pubClient.publish(channel: "runCommand", stop)
                    exit(0)
                } catch {
                    exit(1)
                }
            }
            
            console.print(log)
        }
    }
    
    static func gitHash(
        console: ConsoleProtocol,
        repo: String,
        envName: String,
        with token: AccessToken
        ) throws {
        let listenChannel = UUID().uuidString
        let replicaController = repo + "-" + envName
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("rc", replicaController)
        try message.set("environment", envName)
        
        var start = message
        try start.set("status", "start")
        
        var stop = message
        try stop.set("status", "exit")
        
        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "redis.eu.vapor.cloud", port: 6379, password: nil)
        try pubClient.publish(channel: "gitHash", start)
        console.registerKillListener { _ in
            _ = try? pubClient.publish(channel: "gitHash", stop)
        }
        
        let listenClient = try TCPClient(hostname: "redis.eu.vapor.cloud", port: 6379, password: nil)
        try listenClient.subscribe(channel: listenChannel) { ( data) in
            guard
                let log = data?
                    .array?
                    .flatMap({ $0?.bytes })
                    .last?
                    .split(separator: .space, maxSplits: 0)
                    .last?
                    .makeString()
                else { return }
            
            guard log != "EXIT!" else {
                do {
                    _ = try pubClient.publish(channel: "gitHash", stop)
                    exit(0)
                } catch {
                    exit(1)
                }
            }
            
            console.print(log)
        }
    }
}

extension Token {
    func rePack() throws -> String {
        var json = JSON([:])
        try json.set("access", access)
        try json.set("refresh", refresh)
        return try json.makeBytes().makeString()
    }
}

class ServerTokens {
    
    public let console: ConsoleProtocol
    
    init(_ console: ConsoleProtocol) {
        self.console = console
    }
    
    public func token(for arguments: [String], repoName: String) throws -> String {
        var token: String = ""
        
        if let chosen = arguments.option("token") {
            token = chosen
        } else {
            let logsBar = console.loadingBar(title: "Getting server tokens")
            logsBar.start()
            let listenChannel = UUID().uuidString
            try CloudRedis.dbServerTokens(console: self.console, application: repoName, channel: listenChannel)
            
            _ = try Portal<Bool>.open { portal in
                let client = try TCPClient.cloudRedis()
                try client.subscribe(channel: listenChannel) { data in
                    do {
                        logsBar.finish()
                        
                        guard let data = data else { return }
                        let json = data.array?
                            .flatMap { $0?.bytes }
                            .last
                            .flatMap { try? JSON(bytes: $0) }
                        
                        let list = try TokenListObject(node: json)
                        
                        self.console.pushEphemeral()
                        
                        token = try self.console.giveChoice(
                            title: "Select server",
                            in: list.tokens
                        )
                        
                        self.console.popEphemeral()
                        
                        portal.close(with: true)
                    } catch {
                        portal.close(with: error)
                    }
                }
            }
        }

        console.detail("token", token)
        
        return token
    }
}

public struct TokenListObject: NodeInitializable {
    public let tokens: [String]
    
    public init(node: Node) throws {
        tokens = try node.get("tokens")
    }
}
