import Node
import Foundation
import Models
import JSON

//
//public struct Project: NodeInitializable {
//    public let id: UUID
//    public let name: String
//    public let color: String
//    public let organizationId: UUID
//
//    public init(node: Node) throws {
//        id = try node.get("id")
//        name = try node.get("name")
//        color = try node.get("color")
//        // some endpoints don't return full object,
//        // this is easier for now
//        organizationId = try node.get("organization.id")
//    }
//}

extension Project: Stitched {}
extension Project: Equatable {}
public func == (lhs: Project, rhs: Project) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.color == rhs.color
        && lhs.organization == rhs.organization
}

public func == <T: Identifiable & JSONConvertible & Equatable>(
    lhs: ModelOrIdentifier<T>,
    rhs: ModelOrIdentifier<T>) -> Bool {
    switch (lhs, rhs) {
    case (.identifier(let l), .identifier(let r)):
        return l == r
    case (.model(let l), .model(let r)):
        return l == r
    default:
        return false
    }
}
