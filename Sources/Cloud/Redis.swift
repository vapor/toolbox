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
    
    public init(node: Node) throws {
        hostname = try node.get("hostname") ?? ""
        port = try node.get("port") ?? ""
        environmentId = try node.get("environmentId") ?? ""
        username = try node.get("username") ?? ""
        password = try node.get("password") ?? ""
        type = try node.get("type") ?? ""
        ended = try node.get("ended") ?? false
    }
}

extension Client where StreamType == TCPInternetSocket {
    static func cloudRedis() throws -> TCPClient {
        return try .init(
            //hostname: "redis.eu.vapor.cloud",
            hostname: "127.0.0.1",
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

    static func createDBServer(
        console: ConsoleProtocol,
        name: String,
        size: String,
        engine: String,
        engineVersion: String,
        environments: [String]
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("name", name)
        try message.set("size", size)
        try message.set("engine", engine)
        try message.set("engineVersion", engineVersion)
        try message.set("environments", environments)
        
        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
        try pubClient.publish(channel: "createDatabaseServer", message)
        
        let listenClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
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
    
    static func dbServerLog(
        console: ConsoleProtocol,
        name: String
        ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("channel", listenChannel)
        try message.set("name", name)
        
        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
        try pubClient.publish(channel: "databaseLog", message)
        
        let listenClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
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
        name: String
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("name", name)
        
        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
        try pubClient.publish(channel: "shutdownDatabaseServer", message)
    }
    
    static func getDatabaseInfo(
        console: ConsoleProtocol,
        cloudFactory: CloudAPIFactory,
        environment: String? = "",
        environmentArr: [String?] = [],
        application: String? = ""
    ) throws {
        let listenChannel = UUID().uuidString
        
        var message = JSON([:])
        try message.set("environment", environment ?? "")
        try message.set("environmentArr", environmentArr)
        try message.set("channel", listenChannel)
        
        // Publish start and kill exit
        let pubClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
        try pubClient.publish(channel: "getDatabaseInfo", message)
        
        let listenClient = try TCPClient(hostname: "127.0.0.1", port: 6379, password: nil)
        try listenClient.subscribe(channel: listenChannel) { data in
            do {
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
}

extension Token {
    func rePack() throws -> String {
        var json = JSON([:])
        try json.set("access", access)
        try json.set("refresh", refresh)
        return try json.makeBytes().makeString()
    }
}
