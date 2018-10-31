import Vapor

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
    public static func Access(with token: Token, on container: Container) -> ResourceAccess<CloudApp> {
        return .init(token: token, baseUrl: applicationsUrl, on: container)
    }
}
