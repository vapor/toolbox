import libc
import Foundation


// MARK: ShellCommand, PosixSubsystem, Shell


public protocol PosixSubsystem {
    func system(_ command: String) -> Int32
    func fileExists(_ path: String) -> Bool
    func commandExists(_ command: String) -> Bool
    func getInput() -> String?
    func terminalSize() -> (width: Int, height: Int)?
    func printFancy(_ string: String)
}


extension PosixSubsystem {
    func passes(_ command: String) -> Bool {
        return self.system(command) == 0
    }
}


extension PosixSubsystem {
    // FIXME: consolidate these two
    func run(_ command: String) throws {
        let result = self.system(command)

        if result == 2 {
            throw Error.cancelled(command)
        } else if result != 0 {
            throw Error.system(result)
        }
    }

    func runWithOutput(_ command: String, arguments: [String]) -> (status: Int32, stdout: String?, stderr: String?) {
        let task = NSTask()
        task.launchPath = command
        task.arguments = arguments
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: data, encoding: NSUTF8StringEncoding)
        return (status, stdout, nil)
    }
}


extension PosixSubsystem {
    func printFancy(_ strings: [String]) {
        printFancy(strings.joined(separator: "\n"))
    }
}


public struct Shell: PosixSubsystem {

    public func system(_ command: String) -> Int32 {
        return libc.system(command)
    }

    public func fileExists(_ path: String) -> Bool {
        return libc.system("ls \(path) > /dev/null 2>&1") == 0
    }

    public func commandExists(_ command: String) -> Bool {
        return libc.system("hash \(command) 2>/dev/null") == 0
    }

    public func getInput() -> String? {
        return readLine(strippingNewline: true)
    }

    public func terminalSize() -> (width: Int, height: Int)? {
        // Get the columns and lines from tput
        let tput = "/usr/bin/tput"
        if let
            str_cols = runWithOutput(tput, arguments: ["cols"]).stdout?.trim(),
            str_lines = runWithOutput(tput, arguments: ["lines"]).stdout?.trim(),
            cols = Int(str_cols),
            lines = Int(str_lines) {
            return (cols, lines)
        } else {
            return nil
        }
    }

    public func printFancy(_ string: String) {
        let centered: String
        if let size = terminalSize() {
            centered = string.centerTextBlock(width: size.width)
        } else {
            centered = string
        }

        let fancy = centered.colored(with: [
            "*": .magenta,
            "~": .blue,
            "+": .cyan, // Droplet
            "_": .magenta,
            "/": .magenta,
            "\\": .magenta,
            "|": .magenta,
            "-": .magenta,
            ")": .magenta // Title
            ])

        print(fancy)
    }

}


// MARK: ContentProvider, File


protocol ContentProvider {
    var contents: String? { get }
}


public typealias Path = String


extension Path: ContentProvider {
    public var contents: String? {
        return try? String(contentsOfFile: self)
    }
}


// MARK: ArgumentsProvider


protocol ArgumentsProvider {
    static var arguments: [String] { get }
}


extension Process: ArgumentsProvider {}


// Utility functions


public enum Error: ErrorProtocol { // Errors pertaining to running commands
    case system(Int32)
    case failed(String) // user facing error, thrown by execute
    case cancelled(String)
    case terminalSize
}


func extractPackageName(from packageFile: ContentProvider) -> String? {
    return packageFile
        .contents?
        .components(separatedBy: "\n")
        .lazy
        .map { $0.trim() }
        .filter { $0.hasPrefix("name") }
        .first?
        .components(separatedBy: "\"")
        .lazy
        .filter { !$0.hasPrefix("name") }
        .first
}



let asciiArt: [String] = [
     "               **",
     "             **~~**",
     "           **~~~~~~**",
     "         **~~~~~~~~~~**",
     "       **~~~~~~~~~~~~~~**",
     "     **~~~~~~~~~~~~~~~~~~**",
     "   **~~~~~~~~~~~~~~~~~~~~~~**",
     "  **~~~~~~~~~~~~~~~~~~~~~~~~**",
     " **~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
     " **~~~~~~~~~~~~~~~~~~~++++~~~**",
     "  ***~~~~~~~~~~~~~~~++++~~~***",
     "    ****~~~~~~~~~~++++~~****",
     "       *****~~~~~~~~~*****",
     "          *************",
     " ",
     " _       __    ___   ___   ___",
     "\\ \\  /  / /\\  | |_) / / \\ | |_)",
     " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\",
     "   a web framework for Swift",
     " "
]

public func getCommand(id: String, commands: [Command.Type]) -> Command.Type? {
    return commands
        .lazy
        .filter { $0.id == id }
        .first
}
