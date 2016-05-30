#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import Foundation

// MARK: Utilities

@noreturn func fail(_ message: String) {
    print()
    print("Error: \(message)")
    exit(1)
}

enum Error: ErrorProtocol { // Errors pertaining to running commands
    case system(Int32)
    case cancelled
    case terminalSize
}

let whiteSpace = [Character(" "), Character("\n"), Character("\t"), Character("\r")]

extension String {
    func trim(trimCharacters: [Character] = whiteSpace) -> String {
        // while characters
        var mutable = self
        while let next = mutable.characters.first where trimCharacters.contains(next) {
            mutable.remove(at: mutable.startIndex)
        }
        while let next = mutable.characters.last where trimCharacters.contains(next) {
            mutable.remove(at: mutable.index(before: mutable.endIndex))
        }
        return mutable
    }
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

func run(_ command: String) throws {
    let result = system(command)

    if result == 2 {
        throw Error.cancelled
    } else if result != 0 {
        throw Error.system(result)
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

func fileExists(_ fileName: String) -> Bool {
    return system("ls \(fileName) > /dev/null 2>&1") == 0
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
    let cols = try runWithOutput("\(tput) cols").trim(trimCharacters: ["\n"])
    let lines = try runWithOutput("\(tput) lines").trim(trimCharacters: ["\n"])
    
    if let cols = Int(cols), lines = Int(lines) {
        return (cols, lines)
    } else {
        throw Error.terminalSize
    }
}

enum ANSIColor: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case reset = "\u{001B}[0;0m"
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

extension String {
    func centerTextBlock(width: Int, paddingCharacter: Character = " ") -> String {
        // Split the string into lines
        var lines = characters.split(separator: Character("\n")).map(String.init)
        
        // Make sure there's more than one line
        guard lines.count > 0 else {
            return ""
        }
        
        // Find the longest line
        var longestLine = 0
        for line in lines {
            if line.characters.count > longestLine {
                longestLine = line.characters.count
            }
        }
        
        // Calculate the padding and make sure it's greater than or equal to 0
        let padding = max(0, (width - longestLine) / 2)
        
        // Apply the padding to each line
        for i in 0..<lines.count {
            for _ in 0..<padding {
                lines[i].insert(paddingCharacter, at: startIndex)
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    #if os(Linux)
        func hasPrefix(_ str: String) -> Bool {
            let strGen = str.characters.makeIterator()
            let selfGen = self.characters.makeIterator()
            let seq = zip(strGen, selfGen)
            for (lhs, rhs) in seq where lhs != rhs {
                    return false
            }
            return true
        }

        func hasSuffix(_ str: String) -> Bool {
            let strGen = str.characters.reversed().makeIterator()
            let selfGen = self.characters.reversed().makeIterator()
            let seq = zip(strGen, selfGen)
            for (lhs, rhs) in seq where lhs != rhs {
                    return false
            }
            return true
        }
    #endif

    func colored(with colors: [Character: ANSIColor], default defaultColor: ANSIColor = .reset) -> String {
        // Check the string is long enough
        guard characters.count > 0 else {
            return ""
        }
        
        // Create a new string
        var newString = ""
        
        // Add the string to the new string and color it
        var currentColor: ANSIColor = defaultColor
        for character in characters {
            // Check if there is a new color for this character than the one before
            if (colors[character] ?? defaultColor) != currentColor {
                currentColor = colors[character] ?? defaultColor // Update the current color
                newString += currentColor.rawValue // Add the color the new string
            }
            
            newString += String(character) // Add the character to the string
        }
        
        // Reset the colors
        newString += ANSIColor.reset.rawValue
        
        return newString
    }

    func colored(with color: ANSIColor) -> String {
        return color.rawValue + self + ANSIColor.reset.rawValue
    }
}

extension Sequence where Iterator.Element == String {
    func valueFor(argument name: String) -> String? {
        for argument in self where argument.hasPrefix("--\(name)=") {
            return argument.characters.split(separator: "=").last.flatMap(String.init)
        }
        return nil
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        self = self.filter { $0 != element }
    }

    mutating func remove(matching: (Element) -> Bool) {
        self = self.filter { !matching($0) }
    }
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

struct VaporCLI {
    static let commands: [Command.Type] = [
        Help.self, Clean.self, Build.self, Run.self, New.self, SelfCommands.self, Xcode.self, Heroku.self, Docker.self
    ]
}

// MARK: CLI

func getCommand(id: String, commands: [Command.Type]) -> Command.Type? {
    return commands
        .lazy
        .filter { $0.id == id }
        .first
}

var iterator = Process.arguments.makeIterator()

guard let directory = iterator.next() else {
    fail("no directory")
}
guard let commandId = iterator.next() else {
    print("Usage: \(directory) [\(VaporCLI.commands.map({ $0.id }).joined(separator: "|"))]")
    fail("no command")
}
guard let command = getCommand(id: commandId, commands: VaporCLI.commands) else {
    fail("command \(commandId) doesn't exist")
}

command.assertDependenciesSatisfied()

let arguments = Array(iterator)
command.execute(with: arguments, in: directory)
exit(0)
