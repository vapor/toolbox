import Node
import Foundation

public struct Permission: NodeInitializable {
    public let id: UUID
    public let key: String

    public init(node: Node) throws {
        id = try node.get("id")
        key = try node.get("key")
    }
}

extension Permission: Equatable {}
public func == (lhs: Permission, rhs: Permission) -> Bool {
    return lhs.id == rhs.id
        && lhs.key == rhs.key
}
