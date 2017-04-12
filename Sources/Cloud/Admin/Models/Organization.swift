import Node
import Foundation

extension Organization: Stitched {}
extension Organization: Equatable {}
public func == (lhs: Organization, rhs: Organization) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
}
