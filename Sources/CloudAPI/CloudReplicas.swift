import Vapor
import Foundation

public struct CloudReplica: Content {
    public let planID: UUID
    public let replicas: Int
    public let status: String
    public let slug: String
    public let environmentID: UUID
    public let id: UUID
    public let updatedAt: String
    public let createdAt: String
}

public struct CloudLogs: Content {
    public let name: String
    public let logs: String
}
