//import NIO
//import Foundation
//
//public func todo(file: StaticString = #file) -> Never {
//    let file = file.description.split(separator: "/").last ?? "<>"
//    print("file: \(file)")
//    fatalError()
//}
//
//public struct Shell {
//    private init() {}
//
////    public static func bashBackground(_ input: String) throws -> String {
////        return try Process.runBackground("/bin/sh", args: ["-c", input])
////    }
////
////    public static func bash(_ input: String) throws {
////        try Process.run("/bin/sh", args: ["-c", input])
////    }
////
////
////    @discardableResult
////    public static func programExists(_ prgrm: String) throws -> Bool {
////        _ = try Process.resolve(program: prgrm)
////        return true
////    }
//}
//
///// Different types of process output.
//public enum ProcessOutput {
//    /// Standard process output.
//    case stdout(Data)
//    
//    /// Standard process error output.
//    case stderr(Data)
//    
//    public var out: String? {
//        guard case .stdout(let o) = self else { return nil }
//        return String(data: o, encoding: .utf8)
//    }
//    
//    public var err: String? {
//        guard case .stderr(let e) = self else { return nil }
//        return String(data: e, encoding: .utf8)
//    }
//}
//
//extension FileHandle {
//    fileprivate func read() -> String {
//        let data = readDataToEndOfFile()
//        return String(decoding: data, as: UTF8.self)
//    }
//}
//
//extension Process {
//    public static var running: Process?
//}
//
//extension Process {
//    public static func runBackground(_ program: String, args: [String]) throws -> String {
//        // observers
//        let out = Pipe()
//        let err = Pipe()
//        let `in` = Pipe()
//        let task = try launchProcess(path: program, args, stdout: out, stderr: err, stdin: `in`)
//        task.waitUntilExit()
//
//        // read output
//        let stdout = out.fileHandleForReading.read()
//        let stderr = err.fileHandleForReading.read()
//        guard task.terminationStatus == 0 else { throw stderr }
//        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//
//
//    public static func run(_ program: String, args: [String]) throws {
//        let process = try launchProcess(
//            path: program,
//            args,
//            stdout: FileHandle.standardOutput,
//            stderr: FileHandle.standardError,
//            stdin: FileHandle.standardInput
//        )
//        Process.running = process
//        process.waitUntilExit()
//        Process.running = nil
//        guard process.terminationStatus == 0 else { throw "code \(process.terminationStatus)." }
//    }
//    
//    static func resolve(program: String) throws -> String {
//        if program.hasPrefix("/") { return program }
//        let path = try Shell.bashBackground("which \(program)")
//        guard path.hasPrefix("/") else { throw "unable to find executable for \(program)" }
//        return path
//    }
//    
//    /// Powers `Process.execute(_:_:)` methods. Separated so that `/bin/sh -c which` can run as a separate command.
//    private static func launchProcess(path: String, _ arguments: [String], stdout: Any, stderr: Any, stdin: Any) throws -> Process {
//        let path = try resolve(program: path)
//        let process = Process()
//        process.environment = ProcessInfo.processInfo.environment
//        process.launchPath = path
//        process.arguments = arguments
//        process.standardOutput = stdout
//        process.standardError = stderr
//        process.standardInput = stdin
//        process.launch()
//        return process
//    }
//}
