import Globals
import Foundation
import NIOWebSocketClient

public struct Activity: Resource {
    public let id: UUID
}

public struct CloudEnv: Resource {
    public let defaultBranch: String
    public let applicationID: UUID
    public let createdAt: String?
    public let id: UUID
    public let slug: String
    public let regionID: UUID
    public let updatedAt: String?
    public let activity: Activity?
}

extension CloudEnv {
    public func deploy(
        branch: String? = nil,
        with token: Token
    ) throws -> Activity {
        let access = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
        let id = self.id.uuidString.trailingSlash + "deploy"
        let package = [
            "branch": branch ?? defaultBranch
        ]

        let env = try access.update(id: id, with: package)
        guard let activity = env.activity else { throw "unable to find deploy activity." }
        return activity
    }
}

extension Activity {
    public enum Update {
        case connected
        case message(String)
        case close
    }

    private var wssUrl: URL {
        return URL(string: "wss://api.v2.vapor.cloud/v2/activity/activities/\(id.uuidString)/channel")!
    }
    
    private var host: String {
        return wssUrl.host!
    }
    private var uri: String {
        return wssUrl.path
    }
    
    public func listen(_ listener: @escaping (Update) -> Void) throws {
        let client = WebSocketClient(eventLoopGroupProvider: .createNew)
        defer { try! client.syncShutdown() }
        
        let connection = client.connect(host: host, port: 80, uri: uri, headers: [:]) { ws in
            listener(.connected)

            ws.onText { ws, text in
                listener(.message(text))
            }
            
            ws.onBinary { ws, binary in
                print("got binary!!!")
            }

            ws.onCloseCode { _ in
                listener(.close)
            }
        }
        try connection.wait()
    }
}
