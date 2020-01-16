import Foundation

extension Shell {
    func programExists(_ program: String) -> Bool {
        do {
            _ = try self.run("which", program)
            return true
        } catch {
            return false
        }
    }

    func cwd() throws -> String {
        return try ProcessInfo.processInfo.environment["TEST_DIRECTORY"] ?? self.run("pwd")
    }

    func whoami() throws -> String {
        try self.run("whoami")
    }

    func allFiles(in dir: String? = nil) throws -> String {
        var arguments = ["-a"]
        if let dir = dir {
            arguments += [dir]
        }
        return try self.run("ls", arguments)
    }

    func delete(_ path: String) throws {
        try self.run("rm", "-rf", path)
    }

    func move(_ source: String, to destination: String) throws {
        try self.run("mv", source, destination)
    }

    func makeDirectory(_ name: String) throws {
        try self.run("mkdir", "-p", name)
    }

    func readFile(path: String) throws -> String {
        try self.run("cat", path)
    }

    func homeDirectory() throws -> String {
        try self.run("echo", "$HOME")
    }
}
