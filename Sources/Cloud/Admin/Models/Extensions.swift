import Node
import Foundation
import JSON

/// Used to stitch external models into the environment
public protocol Stitched: NodeConvertible {
    var id: Identifier? { get }
    init(json: JSON) throws
    func makeJSON() throws -> JSON
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

extension Identifier {
    func uuid() throws -> UUID {
        return try UUID(node: self)
    }
}

extension Optional where Wrapped == Identifier {
    func uuid() throws -> UUID {
        return try UUID(node: self)
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

    public func makeNode(in context: Context?) throws -> Node {
        let js = try makeJSON()
        return Node(js)
    }
}

