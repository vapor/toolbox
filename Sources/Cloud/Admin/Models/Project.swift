import Node
import Foundation
import Models
import JSON

extension Project: Stitched {}
extension Project: Equatable {}
public func == (lhs: Project, rhs: Project) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.color == rhs.color
        && lhs.organization.id == rhs.organization.id
}

