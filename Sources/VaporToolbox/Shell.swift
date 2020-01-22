import Foundation

extension Process {
    static var shell: Shell {
        .init(program: "/bin/sh")
    }
}
struct Shell {
    let program: String

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

    func which(_ program: String) throws -> String {
        if program.hasPrefix("/") {
            return program
        }
        let result = try self.run("which", program)
        guard result.hasPrefix("/") else {
            throw "unable to find executable for \(program)"
        }
        return result
    }

    @discardableResult
    func run(_ program: String, _ arguments: String...) throws -> String {
        try self.run(program, arguments)
    }

    @discardableResult
    func run(_ program: String, _ arguments: [String]) throws -> String {
        let process = Process(
            program: self.program,
            arguments: ["-c", program + " " + arguments.joined(separator: " ")]
        )
        try process.runUntilExit()
        return process.stdout.read()
    }
}
