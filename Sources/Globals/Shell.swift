import Vapor

public func todo(file: StaticString = #file) -> Never {
    let file = file.description.split(separator: "/").last ?? "<>"
    print("file: \(file)")
    fatalError()
}

extension Process {
    public static func run(_ program: String, args: [String]) throws -> String {
        let task = Process()
        task.launchPath = program
//        if #available(OSX 10.13, *) {
//            task.executableURL = URL(fileURLWithPath: program)
//        } else {
//            fatalError("yell at logan")
//        }
        task.arguments = args
//        print("standard output" + "\(task.standardOutput)")
        let output = Pipe()
        let error = Pipe()
        task.standardOutput = output
        task.standardError = error
        
//        output.fileHandleForReading.readabilityHandler = { [weak output] handle in
//            print("output handle fired")
//            defer { print("output handle done") }
//            let data = handle.readDataToEndOfFile()
//            let str = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
//            guard !str.isEmpty else { return }
//            print(str)
//        }
        
        if #available(OSX 10.13, *) {
            try task.run()
        } else {
            fatalError("yell at logan")
        }
        
        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        
        let op = String(decoding: outputData, as: UTF8.self)
        let err = String(decoding: errorData, as: UTF8.self)
        guard err.isEmpty else { throw err }
        return op.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct Shell {
    @discardableResult
    public static func bash(_ input: String) throws -> String {
        return try Process.run("/bin/sh", args: ["-c", input])
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
}

extension Process {
    /// Executes the supplied program in a new process, blocking until the process completes.
    /// Any data piped to `stdout` during the process will be returned as a string.
    /// If the process exits with a non-zero status code, an error will be thrown containing
    /// the contents of `stderr` and `stdout`.
    ///
    ///     let result = try Process.execute("echo", "hi")
    ///     print(result) /// "hi"
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    public static func execute(_ program: String, _ arguments: String...) throws -> String {
        return try execute(program, arguments)
    }
    
    /// Executes the supplied program in a new process, blocking until the process completes.
    /// Any data piped to `stdout` during the process will be returned as a string.
    /// If the process exits with a non-zero status code, an error will be thrown containing
    /// the contents of `stderr` and `stdout`.
    ///
    ///     let result = try Process.execute("echo", "hi")
    ///     print(result) /// "hi"
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    public static func execute(_ program: String, _ arguments: [String]) throws -> String {
        todo()
//        var stderr: String = ""
//        var stdout: String = ""
//        let status = try asyncExecute(program, arguments, on: EmbeddedEventLoop()) { output in
//            switch output {
//            case .stderr(let data):
//                stderr += String(data: data, encoding: .utf8) ?? ""
//            case .stdout(let data):
//                stdout += String(data: data, encoding: .utf8) ?? ""
//            }
//            }.wait()
//        if status != 0 {
//            throw ProcessExecuteError(status: status, stderr: stderr, stdout: stdout)
//        }
//        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
    /// as it is received. The returned future will finish when the process has terminated.
    ///
    ///     let status = try Process.asyncExecute("echo", "hi", on: ...) { output in
    ///         print(output)
    ///     }.wait()
    ///     print(result) // 0
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    ///     - worker: Worker to perform async task on.
    ///     - output: Handler for the process output.
    /// - returns: A future containing the termination status of the process.
//    public static func asyncExecute(_ program: String, _ arguments: String..., on worker: Worker, _ output: @escaping (ProcessOutput) -> ()) -> Future<Int32> {
//        return asyncExecute(program, arguments, on: worker, output)
//    }
    
    @discardableResult
    public static func _execute(_ program: String, arguments: [String], updates: @escaping (ProcessOutput) -> Void) throws -> Int32 {
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
        
        let process = launchProcess(path: program, arguments, stdout: out, stderr: err)
        process.waitUntilExit()
        running = false
        return process.terminationStatus
    }
    /// Asynchronously the supplied program in a new process. Stderr and stdout will be supplied to the output closure
    /// as it is received. The returned future will finish when the process has terminated.
    ///
    ///     let status = try Process.asyncExecute("echo", ["hi"], on: ...) { output in
    ///         print(output)
    ///     }.wait()
    ///     print(result) // 0
    ///
    /// - parameters:
    ///     - program: The name of the program to execute. If it does not begin with a `/`, the full
    ///                path will be resolved using `/bin/sh -c which ...`.
    ///     - arguments: An array of arguments to pass to the program.
    ///     - worker: Worker to perform async task on.
    ///     - output: Handler for the process output.
    /// - returns: A future containing the termination status of the process.
//    public static func asyncExecute(_ program: String, _ arguments: [String], on worker: Worker, _ output: @escaping (ProcessOutput) -> ()) -> Future<Int32> {
//        if program.hasPrefix("/") {
//            let stdout = Pipe()
//            let stderr = Pipe()
//
//            // will be set to false when the program is done
//            var running = true
//
//            // readabilityHandler doesn't work on linux, so we are left with this hack
//            DispatchQueue.global().async {
//                while running {
//                    let stdout = stdout.fileHandleForReading.availableData
//                    if !stdout.isEmpty {
//                        output(.stdout(stdout))
//                    }
//                }
//            }
//            DispatchQueue.global().async {
//                while running {
//                    let stderr = stderr.fileHandleForReading.availableData
//                    if !stderr.isEmpty {
//                        output(.stderr(stderr))
//                    }
//                }
//            }
//
//            // stdout.fileHandleForReading.readabilityHandler = { handle in
//            //     let data = handle.availableData
//            //     guard !data.isEmpty else {
//            //         return
//            //     }
//            //     output(.stdout(data))
//            // }
//            // stderr.fileHandleForReading.readabilityHandler = { handle in
//            //     let data = handle.availableData
//            //     guard !data.isEmpty else {
//            //         return
//            //     }
//            //     output(.stderr(data))
//            // }
//
//            let promise = worker.eventLoop.newPromise(Int32.self)
//            DispatchQueue.global().async {
//                let process = launchProcess(path: program, arguments, stdout: stdout, stderr: stderr)
//                process.waitUntilExit()
//                running = false
//                promise.succeed(result: process.terminationStatus)
//            }
//            return promise.futureResult
//        } else {
//            var resolvedPath: String?
//            return asyncExecute("/bin/sh", ["-c", "which \(program)"], on: worker) { o in
//                switch o {
//                case .stdout(let data): resolvedPath = String(data: data, encoding: .utf8)?
//                    .trimmingCharacters(in: .whitespacesAndNewlines)
//                default: break
//                }
//                }.flatMap { status in
//                    guard let path = resolvedPath, path.hasPrefix("/") else {
//                        throw CoreError(identifier: "executablePath", reason: "Could not find executable path for program: \(program).")
//                    }
//                    return asyncExecute(path, arguments, on: worker, output)
//            }
//        }
//    }
    
    private static func resolve(program: String) throws -> String {
        if program.hasPrefix("/") { return program }
        let path = try Process.run("/bin/sh", args: ["-c", "which \(program)"])
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
