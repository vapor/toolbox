import Vapor

public struct Git {
    public static func checkout(gitDir: String, workTree: String, checkout: String) throws -> String {
        let gitDir = "--git-dir=\(gitDir)"
        let workTree = "--work-tree=\(workTree)"
        return try run(gitDir, workTree, "checkout", checkout)
    }

    public static func create(gitDir: String) throws -> String {
        let gitDir = "--git-dir=\(gitDir)"
        return try run(gitDir, "init")
    }

    public static func commit(gitDir: String, workTree: String, msg: String) throws {
        let gitDir = "--git-dir=\(gitDir)"
        let workTree = "--work-tree=\(workTree)"
        try run(gitDir, workTree, "add", ".")
        try run(gitDir, workTree, "commit", "-m", msg)
    }

    public static func clone(repo: String, toFolder folder: String) throws -> String {
        return try run("clone", repo, folder)
    }

    public static func isGitRepository() -> Bool {
        do {
            let _ =  try run("status", "--porcelain")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        } catch {
            return false
        }
    }

    public static func currentBranch() throws -> String {
        let branch = try run("branch")
            .split(separator: "\n")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { $0.hasPrefix("* ") }
            // drop '* '
            .flatMap { $0.dropFirst(2) }
            .flatMap(String.init)

        guard let value = branch else { throw "unable to detect git branch" }
        return value
    }

    public static func branch(_ branch: String, matchesRemote remote: String) throws -> (ahead: Bool, behind: Bool) {
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

    public static func pushCloud(branch: String, force: Bool) throws {
        if force {
            try run("push", "cloud", branch, "-f")
        } else {
            try run("push", "cloud", branch)
        }
    }

    public static func setRemote(named name: String, url: String) throws {
        try run("remote", "add", name, url)
    }

    public static func removeRemote(named name: String) throws {
        try run("remote", "remove", name)
    }

    public static func isClean() throws -> Bool {
        return try run("status", "--porcelain")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    public static func commitChanges(msg: String) throws {
        try run("commit", "-m", msg)
    }

    public static func isCloudConfigured() throws -> Bool {
        return try run("remote")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains("cloud")
    }

    public static func cloudUrl() throws -> String {
        let isConfigured = try isCloudConfigured()
        guard isConfigured else { throw "cloud url not yet configured. use `vapor cloud remote set`" }
        return try run("remote", "get-url", "cloud").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    private static func run(_ args: String...) throws -> String {
        todo()
//        return try Process.execute("git", args)
    }
}


