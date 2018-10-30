import Vapor

struct Git {
    static func isGitRepository() throws -> Bool {
        do {
            let _ =  try run("status", "--porcelain")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        } catch {
            return false
        }
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
        guard isConfigured else { throw "cloud url not yet configured" }
        return try run("remote", "get-url", "cloud").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    private static func run(_ args: String...) throws -> String {
        return try Process.execute("git", args)
    }
}


