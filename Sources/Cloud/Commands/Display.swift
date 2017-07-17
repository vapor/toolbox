import Bits
import Console
import Foundation
import JSON
import Node

public final class LogContext: Context {
    internal static let shared = LogContext()
    fileprivate init() {}
}

public let logContext = LogContext.shared

extension Context {
    public var isLog: Bool {
        guard let _ = self as? LogContext else { return false }
        return true
    }
}

extension User {
    public func makeNode(in context: Context?) throws -> Node {
        var node = try makeJSON().converted(to: Node.self)
        guard context?.isLog == true else { return node }
        // overwrite nested name struct for logging
        try node.set("name", name.full)
        return node
    }
}

extension ConsoleProtocol {
    func log(_ loggable: NodeRepresentable, padding: Int = 0) {
        let title = loggable.logTitle
            .appending(":")
            .add(padding: padding)
        success(title)

        let subPadding = padding + 2
        let json: Node
        do {
            json = try loggable.makeNode(in: logContext)
        } catch {
            json = ["error": error.localizedDescription.makeNode(in: logContext)]
        }

        json.object?.sorted { lhs, rhs in
            let lk = lhs.key.lowercased()
            let rk = rhs.key.lowercased()
            // id prioritized down
            if lk == "id" {
                return false
            } else if rk == "id" {
                return true
            // name prioritized up
            } else if lk == "name" {
                return true
            } else if rk == "name" {
                return false
            } else {
                return lk < rk
            }
        } .forEach { k, v in
            guard let v = v.string else { return }

            let k = k.capitalizedFirst.appending(": ").add(padding: subPadding)
            info(k, newLine: false)
            print(v)
        }
    }
}

extension Stitched {
    fileprivate var idString: String {
        return id?.string ?? "<>"
    }
}

extension String {
    fileprivate var capitalizedFirst: String {
        var bytes = makeBytes()
        guard !bytes.isEmpty else { return "" }
        let first = bytes.prefix(1).uppercased[0]
        bytes[0] = first
        return bytes.makeString()
    }

    fileprivate func add(padding: Int) -> String {
        let bytes = Bytes(repeating: .space, count: padding)
        let pad = bytes.makeString()
        return pad + self
    }
}

public typealias LogValue = (key: String, value: String)
public typealias LogValues = [LogValue]

public protocol InformLoggable: JSONRepresentable {
    var logTitle: String { get }
    var logValues: LogValues { get }
}

extension NodeRepresentable {
    public var logTitle: String {
        return "\(Self.self)".components(separatedBy: ".").last ?? ""
    }
}

extension Array where Element == LogValue {
    mutating func add(_ key: String, _ value: String?) {
        guard let value = value else { return }
        append((key, value))
    }
    mutating func add(_ key: String, _ id: Identifier?) {
        guard let id = id?.string else { return }
        append((key, id))
    }
}

extension Organization: InformLoggable {
    public var logValues: [(key: String, value: String)] {
        var values = LogValues()
        values.add("Name", name)
        values.add("Id", id)
        return values
    }
}

extension Project: InformLoggable {
    public var logValues: [(key: String, value: String)] {
        var values = LogValues()
        values.add("Name", name)
        values.add("Color", color)
        values.add("Id", id)
        return values
    }
}

