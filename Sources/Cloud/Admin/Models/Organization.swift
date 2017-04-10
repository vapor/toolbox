import Node
import Foundation

//public struct Organization: NodeInitializable {
//    public let id: UUID
//    public let name: String
//    public init(node: Node) throws {
//        id = try node.get("id")
//        name = try node.get("name")
//    }
//}

extension Organization: Stitched {}
extension Organization: Equatable {}
public func == (lhs: Organization, rhs: Organization) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
}
