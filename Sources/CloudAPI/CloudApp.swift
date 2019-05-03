import Vapor
import Globals

public struct CloudApp: Codable {
    public let updatedAt: String
    public let name: String
    public let createdAt: String
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
    public func environments(with token: Token) throws -> [CloudEnv] {
        let appEnvsUrl = applicationsUrl.trailingSlash
            + id.uuidString.trailingSlash
            + "environments"
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
        return try envAccess.list()
    }
}

extension ResourceAccess where T == CloudApp {
    public func matching(slug: String) throws -> CloudApp {
        let apps = try list(query: "slug=\(slug)&exact=true")
        guard apps.count == 1 else { throw "unable to find app matching slug: \(slug)" }
        return apps[0]
    }

    public func matching(cloudGitUrl: String) throws -> CloudApp {
        let apps = try list(query: "gitURL=\(cloudGitUrl)")
        guard apps.count == 1 else { throw "No app found at \(cloudGitUrl)." }
        return apps[0]
    }
}

