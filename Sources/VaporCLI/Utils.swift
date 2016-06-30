import libc


// MARK: ShellCommand, PosixSubsystem, Shell


public protocol PosixSubsystem {
    func system(_ command: String) -> Int32
    func fileExists(_ path: String) -> Bool
    func commandExists(_ command: String) -> Bool
    func getInput() -> String?
}


extension PosixSubsystem {
    func passes(_ command: String) -> Bool {
        return self.system(command) == 0
    }
}


extension PosixSubsystem {
    func run(_ command: String) throws {
        let result = self.system(command)

        if result == 2 {
            throw Error.cancelled(command)
        } else if result != 0 {
            throw Error.system(result)
        }
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
    // cannot use `static var arguments: [String] { get }`
    // because
//    static func arguments() -> [String]
    static var arguments: [String] { get }
}


extension Process: ArgumentsProvider {}


// Utility functions

// FIXME: remove once everything is migrated to PosixSystem
@noreturn public func fail(_ message: String, cancelled: Bool = false) {
    print()
    print("Error: \(message)")
    if !cancelled {
        print("Note: Make sure you are using Swift 3.0 Snapshot 06-06")
    }
    exit(1)
}

public enum Error: ErrorProtocol { // Errors pertaining to running commands
    case system(Int32)
    case failed(String) // user facing error, thrown by execute
    case cancelled(String)
    case terminalSize
}


func runWithOutput(_ command: String) throws -> String { // Command needs to use the absolute path for the executable
    // Run the command
    let fp = popen(command, "r")

    defer {
        pclose(fp)
    }

    if let fp = fp {
        // Get the output of the command
        let pathSize: Int32 = 1035
        let path : UnsafeMutablePointer<Int8> = UnsafeMutablePointer(allocatingCapacity: Int(pathSize))
        var output = ""
        while fgets(path, pathSize - 1, fp) != nil {
            output += String(cString: path)
        }

        return output
    } else {
        throw Error.system(1)
    }
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

func terminalSize() throws -> (width: Int, height: Int) {
    // Get the columns and lines from tput
    let tput = "/usr/bin/tput"
    let cols = try runWithOutput("\(tput) cols").trim(characters: ["\n"])
    let lines = try runWithOutput("\(tput) lines").trim(characters: ["\n"])

    if let cols = Int(cols), lines = Int(lines) {
        return (cols, lines)
    } else {
        throw Error.terminalSize
    }
}

func printFancy(_ strings: [String]) {
    printFancy(strings.joined(separator: "\n"))
}

func printFancy(_ string: String) {
    let centered: String
    do {
        let size = try terminalSize()
        centered = string.centerTextBlock(width: size.width)
    } catch {
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
