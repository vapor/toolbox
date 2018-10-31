import Vapor

public struct Token: Content, Hashable {
    public let expiresAt: Date
    public let id: UUID
    public let userID: UUID
    private let token: String

    // public renname cuz it's a touch confusing token.token
    public var key: String { return token }
}
