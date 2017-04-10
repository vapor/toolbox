import Node
import Foundation
import Admin
import JSON
@_exported import Admin

//public struct User: NodeInitializable {
//    public let id: UUID
//    public let firstName: String
//    public let lastName: String
//    public let email: String
//    public let imageUrl: String?
//
//    public init(node: Node) throws {
//        id = try node.get("id")
//        firstName = try node.get("name.first")
//        lastName = try node.get("name.last")
//        email = try node.get("email")
//        imageUrl = try node.get("image")
//    }
//}

extension User {
    public func uuid() throws -> UUID {
        return try UUID(node: id)
    }
}

extension User: NodeInitializable {
    public convenience init(node: Node) throws {
        guard node.context.isJSON else { throw "Expected JSON" }
        let json = JSON(node)
        try self.init(json: json)
    }
}
extension Name: Equatable {}
public func == (lhs: Name, rhs: Name) -> Bool {
    return lhs.first == rhs.first
        && lhs.last == rhs.last
}

extension User: Equatable {}
public func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.email == rhs.email
        && lhs.image == rhs.image
}
