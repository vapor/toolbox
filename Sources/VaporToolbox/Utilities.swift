import Vapor

extension String: Error {}

struct Shell {
    @discardableResult
    static func bash(_ input: String) throws -> String {
        return try Process.execute("/bin/sh", "-c", input)
    }

    static func delete(_ path: String) throws {
        try bash("rm -rf \(path)")
    }

    static func cwd() throws -> String {
        return try Environment.get("TEST_DIRECTORY") ?? bash("dirs -l")
    }

    static func allFiles(in dir: String? = nil) throws -> String {
        var command = "ls -lah"
        if let dir = dir {
            command += " \(dir)"
        }
        return try Shell.bash(command)
    }

    static func readFile(path: String) throws -> String {
        return try bash("cat \(path)").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
