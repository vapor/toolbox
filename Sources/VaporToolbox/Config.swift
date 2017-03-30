import Node
import JSON
import Core
import Foundation
import Console

extension Command {
    public var project: Project {
        return Project(console)
    }
}

public final class Project {
    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
        self.console = console
    }

    /// Access project metadata through 'swift package dump-package'
    public func package() throws -> JSON? {
        let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
        return try? JSON(bytes: dump.makeBytes())
    }

    public func isSwiftProject() -> Bool {
        do {
            let result = try console.backgroundExecute(program: "ls", arguments: ["./Package.swift"])
            return result.trim() == "./Package.swift"
        } catch {
            return false
        }
    }

    public func isVaporProject() throws -> Bool {
        return try dependencyURLs().contains("https://github.com/vapor/vapor.git")
    }

    /// Get the name of the current Project
    public func packageName() throws -> String {
        guard let name = try package()?["name"]?.string else {
            throw ToolboxError.general("Unable to determine package name.")
        }
        return name
    }

    /// Dependency URLs of current Project
    public func dependencyURLs() throws -> [String] {
        let dependencies = try package()?["dependencies.url"]?
            .array?
            .flatMap { $0.string }
            ?? []
        return dependencies
    }

    public func checkouts() throws -> [String] {
        return try FileManager.default
            .contentsOfDirectory(atPath: "./.build/checkouts/")
    }

    public func vaporCheckout() throws -> String? {
        return try checkouts()
            .lazy
            .filter { $0.hasPrefix("vapor.git") }
            .first
    }
    
    public func vaporVersion() throws -> String {
        guard let checkout = try vaporCheckout() else {
            throw ToolboxError.general("Unable to locate vapor dependency")
        }

        let gitDir = "--git-dir=./.build/checkouts/\(checkout)/.git"
        let workTree = "--work-tree=./.build/checkouts/\(checkout)"
        let version = try console.backgroundExecute(
            program: "git",
            arguments: [
                gitDir,
                workTree,
                "describe",
                "--exact-match",
                "--tags",
                "HEAD"
            ]
        )
        return version.trim()
    }

    public func availableExecutables() throws -> [String] {
        let executables = try console.backgroundExecute(
            program: "find",
            arguments: ["./Sources", "-type", "f", "-name", "main.swift"]
        )
        let names = executables.components(separatedBy: "\n")
            .flatMap { path in
                return path.components(separatedBy: "/")
                    .dropLast() // drop main.swift
                    .last // get name of source folder
        }

        // For the use case where there's one package
        // and user hasn't setup lower level paths
        return try names.map { name in
            if name == "Sources" {
                return try packageName()
            }
            return name
        }
    }

    public func buildFolderExists() -> Bool {
        do {
            let ls = try console.backgroundExecute(program: "ls", arguments: ["-a", "."])
            return ls.contains(".build")
        } catch { return false }
    }
}


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
        let data = try DataFile().load(path: path)
        guard path.hasSuffix(".json") else { return .bytes(data) }
        return try JSON(bytes: data).converted()
    }
}
