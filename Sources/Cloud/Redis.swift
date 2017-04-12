import Redis
import Node
import JSON
import Core
import Foundation
import libc
import Sockets

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

extension Client where StreamType == TCPInternetSocket {
    static func cloudRedis() throws -> TCPClient {
        return try .init(
            hostname: "redis.eu.vapor.cloud",
            port: 6379,
            password: nil
        )
    }
}

public final class Redis {
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
        since: String,
        with token: Token
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
        try message.set("token", token.rePack())

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

    static func runCommand(
        console: ConsoleProtocol,
        command: String,
        repo: String,
        envName: String,
        with token: Token
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
