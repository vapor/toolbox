import Vapor

extension String: Error {}

//func gitIsClean(log: Bool = true) throws {
//            do {
//                let status = try console.backgroundExecute(program: "git", arguments: ["status", "--porcelain"])
//                if status.trim() != "" {
//                    if log {
//                        console.info("All current changes must be committed before running a Heroku init.")
//                    }
//                    throw "Found uncommitted changes."
//                }
//            } catch ConsoleError.backgroundExecute {
//                throw "No .git repository found."
//            }
//}

public func testGit() throws {
    let clean = try Git.isClean()
    print("Is clean: \(clean)")
}

struct Git {
    static func isClean() throws -> Bool {
        return try run("status", "--porcelain")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private static func run(_ args: String...) throws -> String {
        return try Process.execute("git", args)
    }
}


