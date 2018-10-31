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
