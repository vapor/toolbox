import Node
import JSON
import Core
import Foundation
import Console

public final class Config: StructuredDataWrapper {
    public var wrapped: StructuredData
    public var context: Context
    public init(_ wrapped: StructuredData, in context: Context?) {
        self.wrapped = wrapped
        self.context = context ?? emptyContext
    }
}

extension Config {
    public convenience init(rootDirectory: String = "./") throws  {
        let configs = try FileManager.default.vaporConfigFiles(rootDirectory: rootDirectory)
        self.init(Node(configs))
    }
}

extension Config {
    public static func buildFlags(rootDirectory: String = "./", os: String? = nil) throws -> [String] {
        let os = os ?? dynamicOs()
        return try loadFlags(directory: rootDirectory, command: "build", os: os)
    }

    public static func runFlags(rootDirectory: String = "./", os: String? = nil) throws -> [String] {
        let os = os ?? dynamicOs()
        return try loadFlags(directory: rootDirectory, command: "run", os: os)
    }

    public static func testFlags(rootDirectory: String = "./", os: String? = nil) throws -> [String] {
        let os = os ?? dynamicOs()
        return try loadFlags(directory: rootDirectory, command: "test", os: os)
    }

    private static func loadFlags(directory: String, command: String, os: String) throws -> [String] {
        let config = try Config(rootDirectory: directory)

        return config.wrapped["flags", command, os]?
            .array?
            .flatMap { $0.array } // to array of arrays
            .flatMap { $0 } // to contiguous array
            .flatMap { $0.string }
            ?? []
    }

    private static func dynamicOs() -> String {
        #if os(Linux)
        return "linux"
        #else
        return "mac"
        #endif
    }
}

/**
 Not publicizing these because there's some nuance specific to config
 */
extension FileManager {
    func vaporConfigFiles(rootDirectory: String = "./") throws -> [Node] {
        let rootDirectory = rootDirectory.finished(with: "/")

        let rootConfig = loadVaporConfig(directory: rootDirectory)

        let packagesDirectory = rootDirectory + ".build/checkouts/"
        let packagesConfigs = try subDirectories(root: packagesDirectory)
            .map { packagesDirectory + $0 }
            .flatMap(loadVaporConfig)

        return rootConfig.flatMap { [$0] + packagesConfigs } ?? packagesConfigs
    }

    private func loadVaporConfig(directory: String) -> Node? {
        let directory = directory.finished(with: "/")
        return try? Node.loadContents(path: directory + "vapor.json")
    }

    private func subDirectories(root: String) throws -> [String] {
        let root = root.finished(with: "/")
        guard isDirectory(path: root) else { return [] }
        return try contentsOfDirectory(atPath: root).filter { isDirectory(path: root + $0) }
    }

    private func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        _ = fileExists(atPath: path, isDirectory: &isDirectory)
        #if os(Linux)
            return isDirectory
        #else
            return isDirectory.boolValue
        #endif
    }
}


extension Node {
    /**
     Load the file at a path as raw bytes, or as parsed JSON representation
     */
    fileprivate static func loadContents(path: String) throws -> Node {
        let data = try DataFile().read(at: path)
        guard path.hasSuffix(".json") else { return .bytes(data) }
        return try JSON(bytes: data).converted()
    }
}
