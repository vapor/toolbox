import Vapor

public func todo() -> Never {
    fatalError()
}

public struct Shell {
    @discardableResult
    public static func bash(_ input: String) throws -> String {
        todo()
//        return try Process.execute("/bin/sh", "-c", input)
    }

    public static func delete(_ path: String) throws {
        try bash("rm -rf \(path)")
    }

    public static func cwd() throws -> String {
        return try Environment.get("TEST_DIRECTORY") ?? bash("dirs -l")
    }

    public static func allFiles(in dir: String? = nil) throws -> String {
        var command = "ls -lah"
        if let dir = dir {
            command += " \(dir)"
        }
        return try Shell.bash(command)
    }

    public static func readFile(path: String) throws -> String {
        return try bash("cat \(path)").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func homeDirectory() throws -> String {
        return try bash("echo $HOME").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
