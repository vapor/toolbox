@_exported import Shared
import Console
import JSON
import Foundation

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

    public func checkouts() throws -> [String]? {
        guard FileManager.default.fileExists(atPath: "./.build/checkouts/") else {
            return nil
        }
        
        return try FileManager.default
            .contentsOfDirectory(atPath: "./.build/checkouts/")
    }

    public func vaporCheckout() throws -> String? {
        return try checkouts()?
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

//import Console
//import JSON
//import Foundation
//
//extension Command {
//    public var project: Project {
//        return Project(console)
//    }
//}
//
//public final class Project {
//    public let console: ConsoleProtocol
//
//    public init(_ console: ConsoleProtocol) {
//        self.console = console
//    }
//
//    /// Access project metadata through 'swift package dump-package'
//    public func package() throws -> JSON? {
//        let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
//        return try? JSON(bytes: dump.makeBytes())
//    }
//
//    public func isSwiftProject() -> Bool {
//        do {
//            let result = try console.backgroundExecute(program: "ls", arguments: ["./Package.swift"])
//            return result.trim() == "./Package.swift"
//        } catch {
//            return false
//        }
//    }
//
//    public func isVaporProject() throws -> Bool {
//        return try dependencyURLs().contains("https://github.com/vapor/vapor.git")
//    }
//
//    /// Get the name of the current Project
//    public func packageName() throws -> String {
//        guard let name = try package()?["name"]?.string else {
//            throw ToolboxError.general("Unable to determine package name.")
//        }
//        return name
//    }
//
//    /// Dependency URLs of current Project
//    public func dependencyURLs() throws -> [String] {
//        let dependencies = try package()?["dependencies.url"]?
//            .array?
//            .flatMap { $0.string }
//            ?? []
//        return dependencies
//    }
//
//    public func checkouts() throws -> [String] {
//        return try FileManager.default
//            .contentsOfDirectory(atPath: "./.build/checkouts/")
//    }
//
//    public func vaporCheckout() throws -> String? {
//        return try checkouts()
//            .lazy
//            .filter { $0.hasPrefix("vapor.git") }
//            .first
//    }
//
//    public func vaporVersion() throws -> String {
//        guard let checkout = try vaporCheckout() else {
//            throw ToolboxError.general("Unable to locate vapor dependency")
//        }
//
//        let gitDir = "--git-dir=./.build/checkouts/\(checkout)/.git"
//        let workTree = "--work-tree=./.build/checkouts/\(checkout)"
//        let version = try console.backgroundExecute(
//            program: "git",
//            arguments: [
//                gitDir,
//                workTree,
//                "describe",
//                "--exact-match",
//                "--tags",
//                "HEAD"
//            ]
//        )
//        return version.trim()
//    }
//
//    public func availableExecutables() throws -> [String] {
//        let executables = try console.backgroundExecute(
//            program: "find",
//            arguments: ["./Sources", "-type", "f", "-name", "main.swift"]
//        )
//        let names = executables.components(separatedBy: "\n")
//            .flatMap { path in
//                return path.components(separatedBy: "/")
//                    .dropLast() // drop main.swift
//                    .last // get name of source folder
//        }
//
//        // For the use case where there's one package
//        // and user hasn't setup lower level paths
//        return try names.map { name in
//            if name == "Sources" {
//                return try packageName()
//            }
//            return name
//        }
//    }
//
//    public func buildFolderExists() -> Bool {
//        do {
//            let ls = try console.backgroundExecute(program: "ls", arguments: ["-a", "."])
//            return ls.contains(".build")
//        } catch { return false }
//    }
//}
