import Foundation

extension Process {
    static var git: Git {
        .init()
    }
    struct Git {
        @discardableResult
        func run(_ command: String, _ arguments: String...) throws -> String {
            try self.run(command, arguments)
        }

        @discardableResult
        func run(_ command: String, _ arguments: [String]) throws -> String {
            try Process.run(Process.shell.which("git"), [command] + arguments)
        }
    }
}

extension Process.Git {
    func checkout(gitDir: String, workTree: String, checkout: String) throws -> String {
        let gitDir = "--git-dir=\(gitDir)"
        let workTree = "--work-tree=\(workTree)"
        return try run(gitDir, workTree, "checkout", checkout)
    }

    func create(gitDir: String) throws -> String {
        let gitDir = "--git-dir=\(gitDir)"
        return try run(gitDir, "init")
    }

    func commit(gitDir: String, workTree: String, msg: String) throws {
        let gitDir = "--git-dir=\(gitDir)"
        let workTree = "--work-tree=\(workTree)"
        try run(gitDir, workTree, "add", ".")
        try run(gitDir, workTree, "commit", "-m", msg)
    }

    func clone(repo: String, toFolder folder: String, branch: String? = nil) throws -> String {
        if let branch = branch {
            return try run("clone", "--branch", branch, repo, folder)
        } else {
            return try run("clone", repo, folder)
        }
    }

    func isGitRepository() -> Bool {
        do {
            let _ = try run("status", "--porcelain")
            return true
        } catch {
            return false
        }
    }

    func currentBranch() throws -> String {
        let branch = try run("branch")
            .split(separator: "\n")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { $0.hasPrefix("* ") }
            .flatMap {
                $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            }
        guard let value = branch else { throw "unable to detect git branch" }
        return value
    }

    func branch(_ branch: String, matchesRemote remote: String) throws -> (ahead: Bool, behind: Bool) {
        let response = try run(
            "log",
            "--left-right",
            "--graph",
            "--cherry-pick",
            "--oneline",
            "\(branch)...\(remote)/\(branch)"
        )

        // Local is AHEAD of remote
        // < 5936b4f (HEAD -> cloud-api) more cloud commands
        // < d352994 going to test alternative websocket
        // Local is BEHIND remote
        // > 8830125 (origin/cloud-api) more deploy work
        let logs = response
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let ahead = logs.filter { $0.hasPrefix("<") } .count > 0
        let behind = logs.filter { $0.hasPrefix(">") } .count > 0
        return (ahead, behind)
    }

    func push(branch: String, remote: String, force: Bool) throws {
        if force {
            try run("push", remote, branch, "-f")
        } else {
            try run("push", remote, branch)
        }
    }

    func setRemote(named name: String, url: String) throws {
        try run("remote", "add", name, url)
    }

    func removeRemote(named name: String) throws {
        try run("remote", "remove", name)
    }

    func hasRemote(named name: String) -> Bool {
        do {
            try run("remote", "get-url", name)
            return true
        } catch {
            return false
        }
    }

    func isClean() throws -> Bool {
        return try run("status", "--porcelain")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    func addChanges() throws {
        try run ("add", ".")
    }
    func commitChanges(msg: String) throws {
        try run("commit", "-m", msg)
    }
}
