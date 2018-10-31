import Vapor

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

extension CloudApp {
    public func environments(with token: Token, on container: Container) -> Future<[CloudEnv]> {
        let appEnvsUrl = applicationsUrl.trailSlash
            + id.uuidString.trailSlash
            + "environments"
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl, on: container)
        return envAccess.list()
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

    public func listen(on container: Container, _ listener: @escaping (Update) -> Void) -> Future<Void> {
        let ws = makeWebSocketClient(url: wssUrl, on: container)
        return ws.flatMap { ws in
            listener(.connected)

            // Logs
            ws.onText { ws, text in
                listener(.message(text))
            }

            // Close
            return ws.onClose.map {
                listener(.close)
            }
        }
    }
}
