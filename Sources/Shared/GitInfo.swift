import Console
import Foundation
import URI

extension Array {
    func suffix(while pass: (Element) -> Bool) -> ArraySlice<Element> {
        return reversed().prefix(while: pass)
    }
}

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

    public func localBranches() throws -> [String] {
        try assertGitRepo()

        return try console.git(["branch"])
            .components(separatedBy: "\n")
            .map { branch in
                let trim = branch.trim()
                guard trim.hasPrefix("* ") else { return trim }
                // drop '* '
                return trim.bytes.dropFirst(2).makeString()
            }
            .filter { !$0.isEmpty }
    }

    public func remoteBranches(for remote: String) throws -> [String] {
        let prefix = remote + "/"
        let prefixLength = prefix.makeBytes().count
        return try console.git(["branch", "-r"])
            .components(separatedBy: "\n")
            .map { $0.trim() }
            .filter { $0.hasPrefix(prefix) && !$0.contains("->") }
            .map { $0.makeBytes().dropFirst(prefixLength).makeString() }
    }

    public func remote(forUrl expect: String) throws -> String? {
        guard let expect = resolvedUrl(expect) else { return nil }
        return try remotes()
            .lazy
            .filter { _, url in
                guard let resolved = self.resolvedUrl(url) else { return false }
                return resolved == expect
            }
            .first?
            .name
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
        let args = ["rev-list", "--left-right", "--count", "\(base)...\(compare)"]
        let result = try console.git(args).trim().makeBytes()
        let behind = result.prefix(while: { $0.isDigit })
        let ahead = result.suffix(while: { $0.isDigit })

        guard let b = Int(behind.makeString()), let a = Int(ahead.makeString()) else {
            throw GeneralError("Unable to get branch position")
        }

        return (b, a)
//        let values = result.trim()
//        print("Got branch result: \(result)")
//        let comps = result.components(separatedBy: " ")
//        print("Coms: \(comps)")
//        let trimmed = comps.map { $0.trim() }
//        print("Trim: \(trimmed)")
//        print("Ints: \(trimmed.flatMap { Int($0) })")
//        // everything here needs to be here
//        let split = result
//            .trim()
//            .components(separatedBy: "\t")
//            .map { $0.trim() }
//            .flatMap { Int($0) }
//        print("Got branch comps: \(split)")
//        guard split.count == 2 else { throw GeneralError("Unable to get branch position") }
//        return (split[0], split[1])
    }

    public func upstreamBranch() throws -> (remote: String, branch: String) {
        try assertGitRepo()

        // http://stackoverflow.com/a/9753364/2611971
        let output = try console.git(
            ["rev-parse", "--abbrev-ref", "--symtolic-full-name", "@{u}"]
        )

        let upstream = output.makeBytes()
            .split(
                separator: .newLine,
                omittingEmptySubsequences: true
            )
            .last
            ?? []
        let components = upstream.split(
            separator: .forwardSlash,
            maxSplits: 1
        )
        guard components.count == 2 else {
            throw GeneralError("unable to get upstream")
        }

        let remote = components[0].makeString()
        let branch = components[1].makeString()
        return (remote, branch)
    }

    public func remoteNames() throws -> [String] {
        try assertGitRepo()
        return try console.git(["remote"])
            .components(separatedBy: "\n")
            .map { $0.trim() }
            .filter { !$0.isEmpty }
    }

    public func remotes() throws -> [(name: String, url: String)] {
        return try remoteNames().map { name in
            let url = try remoteUrl(for: name)
            return (name, url)
        }
    }

    public func remoteUrls() throws -> [String] {
        return try remoteNames().map { try remoteUrl(for: $0) }

    }

    public func trackingOrigin() throws -> Bool {
        return try remoteNames().contains("origin")
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
        return try console.git(["remote", "get-url", remote]).trim()
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
