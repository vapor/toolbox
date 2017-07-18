import Node
import Foundation

public protocol Permission: Stitched {
    var key: String { get }
    var id: Identifier? { get }
}

extension ProjectPermission: Permission {}
extension OrganizationPermission: Permission {}

public func == (lhs: Permission, rhs: Permission) -> Bool {
    return lhs.id == rhs.id
        && lhs.key == rhs.key
}
