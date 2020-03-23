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
    
    /// Styled after PHP's function of the same name. How far we've fallen...
    func escapeshellarg(_ command: String) -> String {
#if os(Windows)
        let escaped = command.replacingOccurrences(of: "\"", with: "^\"")
                             .replacingOccurrences(of: "%", with: "^%")
                             .replacingOccurrences(of: "!", with: "^!")
                             .replacingOccurrences(of: "^", with: "^^")
        return "\"\(escaped)\""
#else
        return "'\(command.replacingOccurrences(of: "'", with: "'\\''"))'"
#endif
    }

    @discardableResult
    func run(_ program: String, _ arguments: String...) throws -> String {
        try self.run(program, arguments)
    }

    @discardableResult
    func run(_ program: String, _ arguments: [String]) throws -> String {
        let process = Process(
            program: self.program,
            arguments: ["-c", "'\(escapeshellarg(program))' \(arguments.map { escapeshellarg($0) }.joined(separator: " "))"]
        )
        try process.runUntilExit()
        return process.stdout.read()
    }
}
