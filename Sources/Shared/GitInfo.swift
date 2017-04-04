import Console
import Foundation
import URI

public final class GitInfo {
    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
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

        let status = try console.git(["status", "--porcelain"])
        return status.isEmpty
    }

    /// This means, as compared to 'base', 'compare' is
    /// 'x' commits ahead, and 'x' commits behind
    ///
    /// to compare remote, for example do
    /// 'branchPosition(base: "master", compare: "origin/master")'
    public func branchPosition(base: String, compare: String) throws -> (behind: Int, ahead: Int) {
        try assertGitRepo()

        // http://stackoverflow.com/a/27940027/2611971
        // returns
        // 1     7
        // where compare is 1 commit behind, and 7 commits ahead
        let result = try console.git(["rev-list", "--left-right", "--count", "\(base)...\(compare)"])
        let split = result.components(separatedBy: " ").map { $0.trim() } .flatMap { Int($0) }
        guard split.count == 2 else { throw GeneralError("Unable to get branch position") }
        return (split[0], split[1])
    }

    public func upstreamBranch() throws -> String {
        try assertGitRepo()

        // http://stackoverflow.com/a/9753364/2611971
        return try console.git(["rev-parse", "--abbrev-ref", "--symtolic-full-name", "@{u}"])
    }

    public func remotes() throws -> [String] {
        try assertGitRepo()
        return try console.git(["remote"])
            .components(separatedBy: "\n")
            .map { $0.trim() }
            .filter { !$0.isEmpty }
    }

    public func remoteUrls() throws -> [String] {
        return try remotes().map { try remoteUrl(for: $0) }

    }

    public func trackingOrigin() throws -> Bool {
        return try remotes().contains("origin")
    }

    public func originUrl() throws -> String {
        return try remoteUrl(for: "origin")
    }

    public func originIsSSH() -> Bool {
        do {
            let url = try originUrl()
            return isSSHUrl(url)
        } catch { return false }
    }

    public func remoteUrl(for remote: String) throws -> String {
        try assertGitRepo()
        return try console.git(["remote", "get-url", remote])
    }

    private func assertGitRepo() throws {
        guard isGitProject() else { throw GeneralError("Expected a git repository") }
    }

    public func resolvedUrl(_ url: String) -> String? {
        if isSSHUrl(url) {
            return url
        } else if let converted = convertToSSHUrl(url) {
            return converted
        } else {
            return nil
        }
    }

    public func isSSHUrl(_ string: String) -> Bool {
        guard string.hasSuffix(".git") else { return false }
        // git@github.com:vapor/vapor.git
        let uri = string.makeBytes()
        // git github.com:vapor/vapor.git
        let atSplit = uri.split(separator: .at, maxSplits: 1, omittingEmptySubsequences: true)
        guard atSplit.count == 2 else { return false }
        // github.com:vapor/vapor.git
        let colonSplit = atSplit[1].split(separator: .colon, maxSplits: 1, omittingEmptySubsequences: true)
        // github.com vapor/vapor.git
        guard colonSplit.count == 2 else { return false }
        return true
    }

    public func convertToSSHUrl(_ string: String) -> String? {
        do {
            let uri = try URI(string)
            var path = uri.path
            if path.hasPrefix("/") { path = path.makeBytes().dropFirst().makeString() }
            if path.hasSuffix("/") { path = path.makeBytes().dropLast().makeString() }
            path = path.finished(with: ".git")

            var host = uri.hostname
            if host.hasPrefix("www.") {
                host = host.makeBytes().dropFirst(4).makeString()
            }
            let converted = "git@\(host):\(path)"
            guard isSSHUrl(converted) else { return nil }
            return converted
        } catch { return nil }
    }
}

extension ConsoleProtocol {
    fileprivate func git(_ arguments: [String]) throws -> String {
        return try backgroundExecute(program: "git", arguments: arguments)
    }
}

extension Command {
    public var gitInfo: GitInfo { return GitInfo(console) }
}
