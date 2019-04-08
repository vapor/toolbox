import Vapor
import Globals

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
        with token: Token,
        on container: Container
    ) throws -> EventLoopFuture<Activity> {
        let access = CloudEnv.Access(with: token, baseUrl: environmentsUrl, on: container)
        let id = self.id.uuidString.trailSlash + "deploy"
        let package = [
            "branch": branch ?? defaultBranch
        ]

        let deploy = access.update(id: id, with: package)
        todo()
//        return deploy.map { env in
//            guard let activity = env.activity else {
//                throw "Unable to find deploy activity."
//            }
//            return activity
//        }
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

    public func listen(on container: Container, _ listener: @escaping (Update) -> Void) -> EventLoopFuture<Void> {
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
