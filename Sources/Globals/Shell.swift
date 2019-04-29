import Vapor

public func todo(file: StaticString = #file) -> Never {
    let file = file.description.split(separator: "/").last ?? "<>"
    print("file: \(file)")
    fatalError()
}

extension Process {
    static func run(_ program: String, args: [String]) throws -> String {
        let task = Process()
        if #available(OSX 10.13, *) {
            task.executableURL = URL(fileURLWithPath: program)
        } else {
            fatalError("yell at logan")
        }
        task.arguments = args
        
        let output = Pipe()
        let error = Pipe()
        task.standardOutput = output
        task.standardError = error
        
        
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
        return op
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
