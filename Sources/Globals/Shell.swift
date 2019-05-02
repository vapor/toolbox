import Vapor

public func todo(file: StaticString = #file) -> Never {
    let file = file.description.split(separator: "/").last ?? "<>"
    print("file: \(file)")
    fatalError()
}

extension Process {
//    public static func run(_ program: String, args: [String]) throws -> String {
//        let task = Process()
//        task.launchPath = program
//        task.arguments = args
//
//        // observers
//        let output = Pipe()
//        let error = Pipe()
//        task.standardOutput = output
//        task.standardError = error
//        task.launch()
//        task.waitUntilExit()
//
//        let outputData = output.fileHandleForReading.readDataToEndOfFile()
//        let errorData = error.fileHandleForReading.readDataToEndOfFile()
//        let op = String(decoding: outputData, as: UTF8.self)
//        let err = String(decoding: errorData, as: UTF8.self)
//        guard err.isEmpty else { throw err }
//        return op.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
}

public struct Shell {
    @discardableResult
    public static func bash(_ input: String) throws -> String {
        return try Process.run("/bin/sh", args: ["-c", input])
//        return try Process.run("/bin/sh", args: ["-c", input])
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

#if !os(iOS)
import NIO

/// Different types of process output.
public enum ProcessOutput {
    /// Standard process output.
    case stdout(Data)
    
    /// Standard process error output.
    case stderr(Data)
    
    public var out: String? {
        guard case .stdout(let o) = self else { return nil }
        return String(data: o, encoding: .utf8)
    }
    
    public var err: String? {
        guard case .stderr(let e) = self else { return nil }
        return String(data: e, encoding: .utf8)
    }
}

extension Process {
    public static func run(_ program: String, args: [String]) throws -> String {
        let task = Process()
        task.launchPath = program
        task.arguments = args
        
        // observers
        let output = Pipe()
        let error = Pipe()
        task.standardOutput = output
        task.standardError = error
        task.launch()
        task.waitUntilExit()
        
        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        let op = String(decoding: outputData, as: UTF8.self)
        let err = String(decoding: errorData, as: UTF8.self)
        guard err.isEmpty else { throw err }
        return op.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @discardableResult
    public static func run(_ program: String, args: [String], updates: @escaping (ProcessOutput) -> Void) throws -> Int32 {
        let program = try resolve(program: program)
        
        let out = Pipe()
        let err = Pipe()
        
        // will be set to false when the program is done
        var running = true
        
        // readabilityHandler doesn't work on linux, so we are left with this hack
        DispatchQueue.global().async {
            while running {
                let stdout = out.fileHandleForReading.availableData
                if !stdout.isEmpty {
                    updates(.stdout(stdout))
                }
            }
        }
        DispatchQueue.global().async {
            while running {
                let stderr = err.fileHandleForReading.availableData
                if !stderr.isEmpty {
                    updates(.stderr(stderr))
                }
            }
        }
        
        let process = launchProcess(path: program, args, stdout: out, stderr: err)
        process.waitUntilExit()
        running = false
        return process.terminationStatus
    }
    
    private static func resolve(program: String) throws -> String {
        if program.hasPrefix("/") { return program }
//        let path = Shell.bash("which \(program)")
        let path = try run("/bin/sh", args: ["-c", "which \(program)"])
        guard path.hasPrefix("/") else { throw "unable to find executable for \(program)" }
        return path
    }
    
    /// Powers `Process.execute(_:_:)` methods. Separated so that `/bin/sh -c which` can run as a separate command.
    private static func launchProcess(path: String, _ arguments: [String], stdout: Pipe, stderr: Pipe) -> Process {
        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.launchPath = path
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        process.launch()
        return process
    }
    
//    public static func execute(_ program: String, _ args: [String]) throws -> String {
//        // observers
//        let output = Pipe()
//        let error = Pipe()
//        let process = launchProcess(path: program, args, stdout: output, stderr: error)
//        process.waitUntilExit()
//
//        // read
//        let outputData = output.fileHandleForReading.readDataToEndOfFile()
//        let errorData = error.fileHandleForReading.readDataToEndOfFile()
//        let op = String(decoding: outputData, as: UTF8.self)
//        let err = String(decoding: errorData, as: UTF8.self)
//        guard err.isEmpty else { throw err }
//        return op.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
}

extension Pipe {
    
}


/// An error that can be thrown while using `Process.execute(_:_:)`
public struct ProcessExecuteError: Error {
    /// The exit status
    public let status: Int32
    
    /// Contents of `stderr`
    public var stderr: String
    
    /// Contents of `stdout`
    public var stdout: String
}

//extension ProcessExecuteError: Debuggable {
//    /// See `Debuggable.identifier`.
//    public var identifier: String {
//        return status.description
//    }
//
//    /// See `Debuggable.reason`
//    public var reason: String {
//        return stderr
//    }
//}

#endif
