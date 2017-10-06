import Node
import Foundation
import JSON

extension Name: Equatable {}
public func == (lhs: Name, rhs: Name) -> Bool {
    return lhs.first == rhs.first
        && lhs.last == rhs.last
}

extension User: Stitched {}
extension User: Equatable {}
public func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.email == rhs.email
        && lhs.image == rhs.image
}
