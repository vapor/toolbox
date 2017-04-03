import Console
import JSON
import Foundation

struct GeneralError: Error {
    let error: String
    init(_ error: String) {
        self.error = error
    }
}

public final class ProjectInfo {
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
            throw GeneralError("Unable to determine package name.")
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
            throw GeneralError("Unable to locate vapor dependency")
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

final class GitInfo {
    let console: ConsoleProtocol

    init(_ console: ConsoleProtocol) {
        self.console = console
    }

    public func isGitProject() -> Bool {
        do {
            // http://stackoverflow.com/a/16925062/2611971
            let ls = try console.git(["rev-parse", "--is-inside-work-tree"])
            return ls.contains("true")
        } catch { return false }
    }

    public func currentBranch() throws -> String {
        try assertGitRepo()

        // http://stackoverflow.com/a/12142066/2611971
        let branch = try console.git(["rev-parse", "--abbrev-ref", "HEAD"])
        return branch.trim()
    }

    public func statusIsClean() throws -> Bool {
        try assertGitRepo()

        let status = try console.backgroundExecute(
            program: "git",
            arguments: ["status", "--porcelain"]
        )
        return status.isEmpty
    }

    /// This means, as compared to 'base', 'compare' is 
    /// 'x' commits ahead, and 'x' commits behind
    ///
    /// to compare remote, for example do 
    /// 'branchPosition(base: "master", compare: "origin/master")'
    public func branchPosition(base: String, compare: String) throws -> (ahead: Int, behind: Int) {
        try assertGitRepo()

        // http://stackoverflow.com/a/27940027/2611971
        // returns
        // 1     7
        // where compare is 1 commit behind, and 7 commits ahead
        let result = try console.git(["rev-list", "--left-right", "--count", "\(base)...\(compare)"])
        let split
    }

    func upstream() {
        //git rev-parse --abbrev-ref --symbolic-full-name @{u}
    }

    private func assertGitRepo() throws {
        guard isGitProject() else { throw GeneralError("Expected a git repository") }
    }
}

extension ConsoleProtocol {
    func git(_ arguments: [String]) throws -> String {
        return try backgroundExecute(program: "git", arguments: arguments)
    }
}
