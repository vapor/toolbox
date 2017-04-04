import Node
import Foundation

public final class User: NodeInitializable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let email: String
    public let imageUrl: String?

    public init(node: Node) throws {
        id = try node.get("id")
        firstName = try node.get("name.first")
        lastName = try node.get("name.last")
        email = try node.get("email")
        imageUrl = try node.get("imageUrl")
    }
}
