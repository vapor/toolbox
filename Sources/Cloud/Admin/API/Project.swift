import Node
import Foundation

public struct Project: NodeInitializable {
    public let id: UUID
    public let name: String
    public let color: String
    public let organizationId: UUID

    public init(node: Node) throws {
        id = try node.get("id")
        name = try node.get("name")
        color = try node.get("color")
        // some endpoints don't return full object,
        // this is easier for now
        organizationId = try node.get("organization.id")
    }
}

extension Project: Equatable {}
public func == (lhs: Project, rhs: Project) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.color == rhs.color
        && lhs.organizationId == rhs.organizationId
}
