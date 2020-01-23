import Foundation

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

extension FileHandle {
    func read() -> String {
        let data = self.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
