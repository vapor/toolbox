import Vapor

struct Git {
    static func isClean() throws -> Bool {
        return try run("status", "--porcelain")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    static func commitChanges(msg: String) throws {
        try run("commit", "-m", msg)
    }

    @discardableResult
    private static func run(_ args: String...) throws -> String {
        return try Process.execute("git", args)
    }
}


