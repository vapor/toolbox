import Vapor

struct Git {
    static func isGitRepository() -> Bool {
        do {
            let _ =  try run("status", "--porcelain")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        } catch {
            return false
        }
    }

    static func currentBranch() throws -> String {
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

    static func branch(_ branch: String, matchesRemote remote: String) throws -> (ahead: Bool, behind: Bool) {
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

    static func setRemote(named name: String, url: String) throws {
        try run("remote", "add", name, url)
    }
    
    static func isClean() throws -> Bool {
        return try run("status", "--porcelain")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    static func commitChanges(msg: String) throws {
        try run("commit", "-m", msg)
    }

    static func isCloudConfigured() throws -> Bool {
        return try run("remote")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains("cloud")
    }

    static func cloudUrl() throws -> String {
        let isConfigured = try isCloudConfigured()
        guard isConfigured else { throw "cloud url not yet configured. use `vapor cloud apps set-remote" }
        return try run("remote", "get-url", "cloud").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    private static func run(_ args: String...) throws -> String {
        return try Process.execute("git", args)
    }
}


