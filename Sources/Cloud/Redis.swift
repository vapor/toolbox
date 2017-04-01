import Redis
import Node
import JSON
import Core

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

public final class Redis {
//     redis = try! Redis.TCPClient(hostname: "34.250.153.203", port: 6379, password: nil)
    static func subscribeDeployLog(id: String, _ updater: @escaping (Update) throws -> Void) throws {
        _ = try Portal<Bool>.open { portal in
            let client = try TCPClient(hostname: "redis.eu.vapor.cloud", port: 6379, password: nil)
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
                    guard update.isLast else { return }
                    portal.close(with: true)
                } catch {
                    portal.close(with: error)
                }
            }
        }
    }
}
