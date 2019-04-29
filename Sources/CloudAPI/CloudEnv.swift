import Vapor
import Globals
import NIOWebSocketClient

public struct Activity: Content {
    public let id: UUID
}

public struct CloudEnv: Content {
    public let defaultBranch: String
    public let applicationID: UUID
    public let createdAt: Date?
    public let id: UUID
    public let slug: String
    public let regionID: UUID
    public let updatedAt: Date?
    public let activity: Activity?
}

extension CloudEnv {
    public func deploy(
        branch: String? = nil,
        with token: Token
    ) throws -> Activity {
        let access = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
        let id = self.id.uuidString.trailSlash + "deploy"
        let package = [
            "branch": branch ?? defaultBranch
        ]

        let env = try access.update(id: id, with: package)
        guard let activity = env.activity else {
            throw "Unable to find deploy activity."
        }
        return activity
    }
}

extension Activity {
    public enum Update {
        case connected
        case message(String)
        case close
    }

    private var wssUrl: String {
        return "wss://api.v2.vapor.cloud/v2/activity/activities/\(id.uuidString)/channel"
    }
    
    private var host: String {
        return "api.v2.vapor.cloud"
    }
    private var uri: String {
        return "/v2/activity/activities/\(id.uuidString)/channel"
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
    
    public func _listen(_ listener: @escaping (Update) -> Void){
        let ws = makeWebSocketClient(url: wssUrl)
        listener(.connected)
        
        // Logs
        ws.onText { ws, text in
            listener(.message(text))
        }
        
        // Close
        let _ = ws.onClose.map {
            listener(.close)
        }
    }
}
