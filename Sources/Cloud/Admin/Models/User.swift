import Node
import Foundation
import Admin
import JSON
@_exported import Admin

/// Used to stitch external models into the environment
public protocol Stitched: NodeInitializable {
    var id: Identifier? { get }
    init(json: JSON) throws
}

extension ModelOrIdentifier {
    var id: Identifier? {
        switch self {
        case .identifier(let id):
            return id
        case .model(let model):
            return model.id
        }
    }
}

extension Stitched {
    public func uuid() throws -> UUID {
        return try UUID(node: id)
    }
}

extension Stitched {
    public init(node: Node) throws {
        let json = JSON(node)
        try self.init(json: json)
    }
}

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
