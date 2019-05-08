import Foundation

public struct Token: Resource, Hashable {
    public let expiresAt: String
    public let id: UUID
    public let userID: UUID
    private let token: String

    // public renname cuz it's a touch confusing token.token
    public var key: String { return token }
}
