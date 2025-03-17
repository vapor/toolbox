import Foundation

extension Process {
    @discardableResult
    static func runUntilExit(
        _ executableURL: URL,
        arguments: [String],
        terminationHandler: (@Sendable (Process) -> Void)? = nil
    ) throws -> Process {
        let process = Process(executableURL, arguments: arguments, terminationHandler: terminationHandler)

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorString = process.errorString!
            let message =
                if errorString.isEmpty {
                    process.outputString!
                } else {
                    errorString
                }
            throw ProcessError(description: message)
        }

        return process
    }

    private convenience init(
        _ executableURL: URL,
        arguments: [String],
        terminationHandler: (@Sendable (Process) -> Void)? = nil
    ) {
        self.init()
        self.environment = ProcessInfo.processInfo.environment
        self.executableURL = executableURL
        self.arguments = arguments
        self.standardInput = Pipe()
        self.standardOutput = Pipe()
        self.standardError = Pipe()
        self.terminationHandler = terminationHandler
    }

    var outputString: String? {
        (self.standardOutput as? Pipe)?.fileHandleForReading.read()
    }

    private var errorString: String? {
        (self.standardError as? Pipe)?.fileHandleForReading.read()
    }
}

extension FileHandle {
    fileprivate func read() -> String {
        String(decoding: self.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ProcessError: Error, CustomStringConvertible {
    var description: String
}

extension Process {
    static var shell: Shell {
        .init(shell: URL(filePath: "/bin/sh"))
    }
}

struct Shell {
    fileprivate let shell: URL

    func which(_ program: String) throws -> URL {
        if program.hasPrefix("/") { return URL(filePath: program) }

        let result = try Process.runUntilExit(self.shell, arguments: ["-c", "'\(escapeshellarg("which"))' \(program)"]).outputString!
        guard result.hasPrefix("/") else {
            throw ShellError.missingExecutable(program)
        }
        return URL(filePath: result)
    }

    func brewInfo(_ package: String) throws -> String {
        try Process.runUntilExit(
            self.shell,
            arguments: ["-c", "'\(escapeshellarg("brew"))' \(escapeshellarg("info")) \(escapeshellarg(package))"]
        ).outputString!
    }
}

enum ShellError: Error {
    case missingExecutable(String)
}
