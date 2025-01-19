import Foundation

extension Process {
    @discardableResult
    static func runUntilExit(
        _ executableURL: URL,
        arguments: [String],
        terminationHandler: (@Sendable (Process) -> Void)? = nil
    ) throws -> Process {
        let process = Self()
        process.environment = ProcessInfo.processInfo.environment
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardInput = Pipe()
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        process.terminationHandler = terminationHandler

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

    fileprivate var outputString: String? {
        (self.standardOutput as? Pipe)?.fileHandleForReading.read()
    }

    fileprivate var errorString: String? {
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

    func which(_ program: String) throws -> String {
        if program.hasPrefix("/") { return program }

        let result = try Process.runUntilExit(self.shell, arguments: ["-c", "'\(escapeshellarg("which"))' \(program)"]).outputString!
        guard result.hasPrefix("/") else {
            throw ShellError.missingExecutable(program)
        }
        return result
    }

    /// Styled after PHP's function of the same name. How far we've fallen...
    func escapeshellarg(_ command: String) -> String {
        #if os(Windows)
            let escaped = command.replacingOccurrences(of: "\"", with: "^\"")
                .replacingOccurrences(of: "%", with: "^%")
                .replacingOccurrences(of: "!", with: "^!")
                .replacingOccurrences(of: "^", with: "^^")
            return "\"\(escaped)\""
        #else
            "'\(command.replacingOccurrences(of: "'", with: "'\\''"))'"
        #endif
    }
}

enum ShellError: Error {
    case missingExecutable(String)
}
