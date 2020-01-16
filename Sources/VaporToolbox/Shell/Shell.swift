import Foundation

struct Shell {
    static var `default`: Shell {
        .init(program: "/bin/sh")
    }

    let program: String

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

extension Process {
    static var running: Process?

    var stdout: FileHandle {
        (self.standardOutput as! Pipe).fileHandleForReading
    }
    var stderr: FileHandle {
        (self.standardError as! Pipe).fileHandleForReading
    }
    var stdin: FileHandle {
        (self.standardInput as! Pipe).fileHandleForWriting
    }

    struct ProcessError: Error, CustomStringConvertible {
        var description: String
    }

    convenience init(program: String, arguments: [String]) {
        self.init()
        self.environment = ProcessInfo.processInfo.environment
        self.executableURL = URL(fileURLWithPath: program)
        self.arguments = arguments
        self.standardInput = Pipe()
        self.standardOutput = Pipe()
        self.standardError = Pipe()
    }

    func onOutput(_ closure: @escaping (String) -> ()) {
        self.stdout.readabilityHandler = { handle in
            closure(handle.read())
        }
    }

    func runUntilExit() throws {
        Process.running = self
        try self.run()
        self.waitUntilExit()
        Process.running = nil
        guard self.terminationStatus == 0 else {
            let message: String
            let stderr = self.stderr.read()
            if stderr.isEmpty {
                message = self.stdout.read()
            } else {
                message = stderr
            }
            throw ProcessError(description: message)
        }
    }


    @discardableResult
    static func run(_ program: String, _ arguments: String...) throws -> String {
        try self.run(program, arguments)
    }

    @discardableResult
    static func run(_ program: String, _ arguments: [String]) throws -> String {
        let task = try Self.new(program, arguments)
        try task.runUntilExit()
        return task.stdout.read()
    }

    static func new(_ program: String, _ arguments: String...) throws -> Process {
        try self.new(program, arguments)
    }

    static func new(_ program: String, _ arguments: [String]) throws -> Process {
        return Process(program: program, arguments: arguments)
    }
}

private extension FileHandle {
    func read() -> String {
        let data = self.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
