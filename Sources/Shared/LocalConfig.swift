import Core
import JSON
import Foundation
import Node

/// When using toolbox in various projects,
/// users may want to add custom configuration files,
/// we will use this as an encapsulation
public final class LocalConfig: StructuredDataWrapper {
    public static let path = "./vapor.json"

    public let context: Context

    public var wrapped: StructuredData {
        didSet {
            do {
                try save()
            } catch {
                print("Local config save failed")
            }
        }
    }

    public init(_ wrapped: StructuredData, in context: Context?) {
        self.wrapped = wrapped
        self.context = context ?? emptyContext
    }

    public static func load() throws -> LocalConfig {
        guard FileManager.default.fileExists(atPath: path) else {
            return LocalConfig([:])
        }
        let bytes = try DataFile.load(path: path)
        let json = try JSON(bytes: bytes)
        return LocalConfig(json)
    }

    public func save() throws {
        let json = JSON(self)
        let bytes = try json.serialize(prettyPrint: true)
        try DataFile.save(bytes: bytes, to: LocalConfig.path)
    }
}
