import Vapor
import Globals

public struct CloudApp: Content {
    public let updatedAt: Date
    public let name: String
    public let createdAt: Date
    public let namespace: String
    public let github: String?
    public let slug: String
    public let organizationID: UUID
    public let gitURL: String
    public let id: UUID
}

extension CloudApp {
    public static func Access(with token: Token) -> ResourceAccess<CloudApp> {
        return .init(token: token, baseUrl: applicationsUrl)
    }
}

extension CloudApp {
    public func environments(with token: Token) -> EventLoopFuture<[CloudEnv]> {
        let appEnvsUrl = applicationsUrl.trailSlash
            + id.uuidString.trailSlash
            + "environments"
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
        return envAccess.list()
    }
}

extension ResourceAccess where T == CloudApp {
    public func matching(slug: String) -> EventLoopFuture<CloudApp> {
        return list(query: "slug=\(slug)&exact=true").flatMapThrowing { apps in
            guard apps.count == 1 else {
                throw "Unable to find app matching slug: \(slug)."
            }
            return apps[0]
        }
    }

    public func matching(cloudGitUrl: String) -> EventLoopFuture<CloudApp> {
        let apps = list(query: "gitURL=\(cloudGitUrl)")
        return apps.flatMapThrowing { apps in
            guard apps.count == 1 else { throw "No app found at \(cloudGitUrl)." }
            return apps[0]
        }
    }
}

