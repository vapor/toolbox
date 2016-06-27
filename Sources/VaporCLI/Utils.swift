import libc

public protocol PosixSubsystem {
    func system(_ command: String) -> Int32
    func fileExists(_ path: String) -> Bool
}

public struct Shell: PosixSubsystem {

    public func system(_ command: String) -> Int32 {
        return libc.system(command)
    }

    public func fileExists(_ path: String) -> Bool {
        return libc.system("ls \(path) > /dev/null 2>&1") == 0
    }

}

public protocol Runnable {
    func run(in: PosixSubsystem) throws
}

public typealias ShellCommand = String

extension ShellCommand: Runnable {

    public func run(in shell: PosixSubsystem) throws {
        let result = shell.system(self)

        if result == 2 {
            throw Error.cancelled
        } else if result != 0 {
            throw Error.system(result)
        }
    }
    
}

// Utility functions

// FIXME: remove once all commands are migrated to Shell.fail
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
    case cancelled
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

func passes(_ command: String) -> Bool {
    return system(command) == 0
}

func getInput() -> String {
    return readLine(strippingNewline: true) ?? ""
}

func commandExists(_ command: String) -> Bool {
    return system("hash \(command) 2>/dev/null") == 0
}

func gitHistoryIsClean() -> Bool {
    return system("test -z \"$(git status --porcelain)\" || exit 1") == 0
}

func readPackageSwiftFile() -> String {
    let file = "./Package.swift"
    do {
        return try String(contentsOfFile: file)
    } catch {
        print()
        print("Unable to find Package.swift")
        print("Make sure you've run `vapor new` or setup your Swift project manually")
        fail("")
    }
}

func extractPackageName(from packageFile: String) -> String {
    let packageName = packageFile
        .components(separatedBy: "\n")
        .lazy
        .map { $0.trim() }
        .filter { $0.hasPrefix("name") }
        .first?
        .components(separatedBy: "\"")
        .lazy
        .filter { !$0.hasPrefix("name") }
        .first

    guard let name = packageName else {
        fail("Unable to extract package name")
    }

    return name
}

func getPackageName() -> String {
    let packageFile = readPackageSwiftFile()
    let packageName = extractPackageName(from: packageFile)
    return packageName
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
