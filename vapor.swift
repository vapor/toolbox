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

extension String {
    func trim(trimCharacter: Character = Character(" ")) -> String {
        // while characters
        var mutable = self
        while let next = mutable.characters.first where next == trimCharacter {
            mutable.remove(at: mutable.startIndex)
        }
        while let next = mutable.characters.last where next == trimCharacter {
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
    let cols = try runWithOutput("\(tput) cols").trim(trimCharacter: "\n")
    let lines = try runWithOutput("\(tput) lines").trim(trimCharacter: "\n")
    
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


// MARK: Command

protocol Command {
    static var id: String { get }
    static var help: [String] { get }

    static var dependencies: [String] { get }
    static var subCommands: [Command.Type] { get }
    static func execute(with args: [String], in directory: String)
}

extension Command {
    static var dependencies: [String] { return [] }
    static var help: [String] { return [] }
}

// sub command related methods
extension Command {
    static var subCommands: [Command.Type] { return [] }

    static func subCommand(forId id: String) -> Command.Type? {
        return subCommands.lazy.filter { $0.id == id }.first
    }

    static func executeSubCommand(with args: [String], in directory: String) {
        var iterator = args.makeIterator()
        guard let cmdId = iterator.next() else {
            fail("\(id) requires a sub command:\n" + description)
        }
        guard let subcommand = subCommand(forId: cmdId) else {
            fail("Unknown \(id) subcommand '\(cmdId)':\n" + description)
        }
        let passthroughArgs = Array(iterator)
        subcommand.execute(with: passthroughArgs, in: directory)
    }
}

extension Command {
    static var description: String {
        // Sub Commands
        let subCommandRows: [String] = subCommands.map { subCommand in
            var output = "      \(subCommand.id.colored(with: .blue)):" 

            if subCommand.help.count > 0 {
                output += "\n"
                output += subCommand.help.map { row in 
                    return "          \(row)"
                }.joined(separator: "\n")
                output += "\n"
            }

            return output
        }
        let subCommandOutput = "\n" + subCommandRows.joined(separator: "\n")

        // Command
        var output = "  \(id.colored(with: .magenta)):"

        if help.count > 0 {
            output += "\n"

            output += help.map { row in
                return "      \(row)"
            }.joined(separator: "\n")

            output += "\n"
        }

        output += subCommandOutput

        return output
    }
}

extension Command {
    static func assertDependenciesSatisfied() {
        for dependency in dependencies where !commandExists(dependency) {
            fail("\(id) requires \(dependency)")
        }
    }
}

// MARK: Tree

var commands: [Command.Type] = []

func getCommand(id: String) -> Command.Type? {
    return commands
        .lazy
        .filter { $0.id == id }
        .first
}

// MARK: Help

struct Help: Command {
    static let id = "help"
    static func execute(with args: [String], in directory: String) {
        print("Usage: \(directory) [\(commands.map({ $0.id }).joined(separator: "|"))]")

        var help = "\nAvailable Commands:\n\n"
        help += commands
            .map { cmd in cmd.description }//"  \(cmd.id):\n\(cmd.description)\n"}
            .joined(separator: "\n")
        help += "\n"
        print(help)

        print("Community:")
        print("    Join our Slack if you have questions,")
        print("    need help, or want to contribute.")
        print("    http://slack.qutheory.io")
        print()
    }
}

commands.append(Help)

// MARK: Clean

struct Clean: Command {
    static let id = "clean"
    static func execute(with args: [String], in directory: String) {
        guard args.isEmpty else {
            fail("\(id) doesn't take any additional parameters")
        }

        do {
            try run("rm -rf Packages .build")
            print("Cleaned.")
        } catch {
            fail("Could not clean.")
        }
    }
}

commands.append(Clean)

// MARK: Build

struct Build: Command {
    static let id = "build"
    static func execute(with args: [String], in directory: String) {
        do {
            try run("swift build --fetch")
        } catch Error.cancelled {
            fail("Fetch cancelled")
        } catch {
            fail("Could not fetch dependencies.")
        }

        do {
            try run("rm -rf Packages/Vapor-*/Sources/Development")
            try run("rm -rf Packages/Vapor-*/Sources/Performance")
            try run("rm -rf Packages/Vapor-*/Sources/Generator")
        } catch {
            print("Failed to remove extra schemes")
        }

        var flags = args
        if args.contains("--release") {
            flags = flags.filter { $0 != "--release" }
            flags.append("-c release")
        }
        do {
            let buildFlags = flags.joined(separator: " ")
            try run("swift build \(buildFlags)")
        } catch Error.cancelled {
            fail("Build cancelled.")
        } catch {
            print()
            print("Make sure you are running Apple Swift version 3.0.")
            print("Vapor only supports the latest snapshot.")
            print("Run swift --version to check your version.")

            fail("Could not build project.")
        }
    }
}

extension Build {
  static var help: [String] {
    return [
      "build <module-name>",
      "Builds source files and links Vapor libs.",
      "Defaults to App/ folder structure."
    ]
  }
}

commands.append(Build)

// MARK: Run

struct Run: Command {
    static let id = "run"
    static func execute(with args: [String], in directory: String) {
        print("Running...")
        do {
            var parameters = args
            let name = args.valueFor(argument: "name") ?? "App"
            parameters.remove { $0.hasPrefix("--name") }

            let folder = args.contains("--release") ? "release" : "debug"
            parameters.remove("--release")

            // All remaining arguments are passed on to app
            let passthroughArgs = args.joined(separator: " ")
            // TODO: Check that file exists
            try run(".build/\(folder)/\(name) \(passthroughArgs)")
        } catch Error.cancelled {
            fail("Run cancelled.")
        } catch {
            fail("Could not run project.")
        }
    }
}

extension Run {
  static var help: [String] {
    return [
      "runs executable built by vapor build.",
      "use --release for release configuration."
    ]
  }
}

commands.append(Run)

// MARK: New

struct New: Command {
    static let id = "new"

    static func execute(with args: [String], in directory: String) {
        guard let name = args.first else {
            print("Usage: \(directory) \(id) <project-name>")
            fail("Invalid number of arguments.")
        }

        let verbose = args.contains("--verbose")
        let curlArgs = verbose ? "" : "-s"
        let tarArgs = verbose ? "v" : ""

        do {
            let escapedName = "\"\(name)\"" // FIX: Doesn’t support names with quotes
            try run("mkdir \(escapedName)")

            print("Cloning example...")

            try run("curl -L \(curlArgs) https://github.com/qutheory/vapor-example/archive/master.tar.gz -o \(escapedName)/vapor-example.tar.gz")

            print("Unpacking...")

            try run("tar -\(tarArgs)xzf \(escapedName)/vapor-example.tar.gz --strip-components=1 --directory \(escapedName)")
            try run("rm \(escapedName)/vapor-example.tar.gz")
            #if os(OSX)
                try run("cd \(escapedName) && vapor xcode")
            #endif

            if commandExists("git") {
                print("Initializing git repository if necessary...")
                system("git init \(escapedName)")
                system("cd \(escapedName) && git add . && git commit -m \"initial vapor project setup\"")
                print()
            }

            print()
            printFancy(asciiArt)
            print()
            printFancy([
                "    Project \"\(name)\" has been created.",
                "Type `cd \(name)` to enter project directory",
                "                   Enjoy!",
            ])
            print()
            #if os(OSX)
                system("open \(escapedName)/*.xcodeproj")
            #endif
        } catch {
            fail("Could not clone repository")
        }
    }
}

extension New {
    static var help: [String] {
        return [
            "new <project-name>",
            "Clones the Vapor Example to a given",
            "folder name and initializes an empty",
            "Git repository inside it."
        ]
    }
}

commands.append(New)

// MARK: Self

extension SelfCommands {
    struct Install: Command {
        static let id = "install"

        static func execute(with args: [String], in directory: String) {
            do {
                try run("mv \(directory) /usr/local/bin/vapor")
                print("Vapor CLI installed.")
            } catch {
                print("Trying with 'sudo'.")
                do {
                    try run("sudo mv \(directory) /usr/local/bin/vapor")
                    print("Vapor CLI installed.")
                } catch {
                    fail("Could not move Vapor CLI to install location.")
                }
            }
        }

        static var help: [String] {
            return [
                "Moves the CLI into the bin so",
                "that it is available in the PATH"
            ]
        }
    }
}

extension SelfCommands {
    struct Update: Command {
        static let id = "update"

        static func execute(with args: [String], in directory: String) {
            let name = "vapor-cli.tmp"
            let quiet = args.contains("--verbose") ? "" : "-s"

            do {
                print("Downloading...")
                try run("curl -L \(quiet) cli.qutheory.io -o \(name)")
            } catch {
                fail("Could not download Vapor CLI.")
            }

            do {
                try run("chmod +x \(name)")
                try run("mv \(name) \(directory)")
                print("Vapor CLI updated.")
            } catch {
                print("Trying with 'sudo'.")
                do {
                    try run("sudo mv \(name) \(directory)")
                    print("Vapor CLI updated.")
                } catch {
                    fail("Could not move Vapor CLI to install location.")
                }
            }

        }

        static var help: [String] {
            return [
                "Downloads the latest version of",
                "the Vapor command line interface."
            ]
        }
    }
}

extension SelfCommands {
    struct Compile: Command {
        static let id = "compile"

        static func execute(with args: [String], in directory: String) {
            let source = "vapor-cli.swift"

            do {
                try run("cp \(directory) \(source)")
            } catch {
                fail("Could not copy source.")
            }

            print("Compiling...")

            let name = "vapor-cli.tmp"
            let compile = "swiftc \(source) -o \(name)"
            #if os(OSX)
                let cmd = "env SDKROOT=$(xcrun -show-sdk-path -sdk macosx) \(compile)"
            #else
                let cmd = compile
            #endif

            do {
                try run(cmd)
            } catch {
                fail("Could not compile.")
            }

            do {
                try run("chmod +x \(name)")
                try run("mv \(name) \(directory)")
            } catch {
                print("Could not move Vapor CLI to install location.")
                print("Trying with 'sudo'.")
                do {
                    try run("sudo mv \(name) \(directory)")
                } catch {
                    fail("Could not move Vapor CLI to install location, giving up.")
                }
            }

            do {
                try run("rm \(source)")
            } catch {

            }

            print("Vapor CLI compiled.")
        }

        static var help: [String] {
            return [
                "Compiles and caches the CLI",
                "to improve performance."
            ]
        }
    }
}


struct SelfCommands: Command {
    static let id = "self"

    static var subCommands: [Command.Type] = [
        SelfCommands.Update.self,
        SelfCommands.Compile.self,
        SelfCommands.Install.self
    ]

    static func execute(with args: [String], in directory: String) {
        executeSubCommand(with: args, in: directory)
    }
}

commands.append(SelfCommands)

// MARK: Xcode

#if os(OSX)

struct Xcode: Command {
    static let id = "xcode"

    static func execute(with args: [String], in directory: String) {
        print("Generating Xcode Project...")

        do {
            try run("swift build --fetch")
            try run("rm -rf Packages/Vapor-*/Sources/Development")
            try run("rm -rf Packages/Vapor-*/Sources/Performance")
            try run("rm -rf Packages/Vapor-*/Sources/Generator")
        } catch {
            print("Failed to remove extra schemes")
        }

        do {
            try run("swift build --generate-xcodeproj")
        } catch {
            print("Could not generate Xcode Project.")
            return
        }

        print("Opening Xcode...")

        do {
            try run("open *.xcodeproj")
        } catch {
            fail("Could not open Xcode Project.")
        }
    }
}

extension Xcode {
  static var help: [String] {
    return [
      "Generates and opens an Xcode Project."
    ]
  }
}

commands.append(Xcode)

#endif

// MARK: Heroku

struct Heroku: Command {
    static let id = "heroku"

    static var dependencies = ["git", "heroku"]

    static var subCommands: [Command.Type] = [
        Heroku.Init.self,
    ]

    static func execute(with args: [String], in directory: String) {
        executeSubCommand(with: args, in: directory)
    }
}

extension Heroku {
    struct Init: Command {
        static let id = "init"

        static var help: [String] {
            return [
                "Configures a new heroku project"
            ]
        }

        static func execute(with args: [String], in directory: String) {
            guard args.isEmpty else { fail("heroku init takes no args") }

            if !gitHistoryIsClean() {
                print("Found Uncommitted Changes")
                print("Setting up heroku requires adding a commit to the repository")
                print("Please commit your current changes before setting up heroku")
                fail("")
            }

            let packageName = getPackageName()
            print("Setting up Heroku for \(packageName) ...")
            print()

            let herokuIsAlreadyInitialized = passes("git remote show heroku")
            if herokuIsAlreadyInitialized {
                print("Found existing heroku app")
                print()
            } else {
                print("Custom Heroku App Name? (return to let Heroku create)")
                let herokuAppName = getInput()
                do {
                    try run("heroku create \(herokuAppName)")
                } catch {
                    fail("unable to create heroku app")
                }
            }

            print("Custom Buildpack? (return to use default)")
            var buildpack = ""
            if let input = readLine(strippingNewline: true) where !buildpack.isEmpty {
                buildpack = input
            } else {
                buildpack = "https://github.com/kylef/heroku-buildpack-swift"
            }

            do {
                try run("heroku buildpacks:set \(buildpack)")
                print("Using buildpack: \(buildpack)")
                print()
            } catch Error.system(let code) where code == 256 {
                print()
            } catch {
                fail("unable to set buildpack: \(buildpack)")
            }

            print("Creating Procfile ...")
            // TODO: Discuss
            // Should it be
            //    let procContents = "web: \(packageName) --port=\\$PORT"
            // It causes errors like that and forces `App` as process.
            // Forces us to use Vapor CLI
            // Maybe that's something we want
            let procContents = "web: App --port=\\$PORT"
            do {
                // Overwrites existing Procfile
                try run("echo \"\(procContents)\" > ./Procfile")
            } catch {
                fail("Unable to make Procfile")
            }

            print()
            print("Would you like to push to heroku now? (y/n)")
            let input = getInput().lowercased()
            if input.hasPrefix("n") {
                print("\n\n")
                print("Make sure to push your changes to heroku using:")
                print("\t'git push heroku master'")
                print("You may need to scale up dynos")
                print("\t'heroku ps:scale web=1'")
                exit(0)
            }

            print()
            print("Pushing to heroku ... this could take a while")
            print()

            system("git add .")
            system("git commit -m \"setting up heroku\"")
            system("git push heroku master")

            print("spinning up dynos ...")
            do {
                try run("heroku ps:scale web=1")
            } catch {
                fail("unable to spin up dynos")
            }
        }
    }
}

commands.append(Heroku)

// MARK: Docker

struct Docker: Command {
    static let id = "docker"

    static var subCommands: [Command.Type] = [
        Docker.Init.self, 
        Docker.Build.self, 
        Docker.Run.self, 
        Docker.Enter.self
    ]

    static func execute(with args: [String], in directory: String) {
        executeSubCommand(with: args, in: directory)
    }
}

extension Docker {
    static var help: [String] {
        return [
            "Setup and run vapor app via docker",
            "sub commands: " + subCommands.map { "\($0.id)" }.joined(separator: "|"),
        ]
    }
}

extension Docker {
    static let swiftVersion: String? = {
        return try? String(contentsOfFile: ".swift-version").trim()
    }()

    static let imageName: String? = {
        if let version = swiftVersion {
            return "qutheory/swift:\(version)"
        } else {
            return nil
        }
    }()
}

extension Docker {
    struct Init: Command {
        static let id = "init"

        static func execute(with args: [String], in directory: String) {
            let quiet = args.contains("--verbose") ? "" : "-s"

            if fileExists("Dockerfile") {
                fail("A Dockerfile already exists in the current directory.\nPlease move it and try again or run `vapor docker build`.")
            }

            do {
                print("Downloading Dockerfile...")
                try run("curl -L \(quiet) docker.qutheory.io -o Dockerfile")
            } catch {
                fail("Could not download Dockerfile.")
            }

            print("Dockerfile created.")
            print("You may now adjust the file or")
            print("run `vapor docker build`.")
        }

        static var help: [String] {
            return [
                "Creates a Dockerfile",
            ]
        }
    }
}

extension Docker {
    struct Build: Command {
        static let id = "build"

        static func execute(with args: [String], in directory: String) {
            guard let
                swiftVersion = Docker.swiftVersion,
                imageName = Docker.imageName
                else {
                fail("Could not determine Swift version (check your .swift-version file)")
            }

            do {
                print("Building docker image with Swift version: \(swiftVersion)")
                print("This may take a few minutes if no layers are cached...")
                let cmd = "docker build --rm -t \(imageName) --build-arg SWIFT_VERSION=\(swiftVersion) ."
                try run(cmd)
            } catch Error.system(let result) {
                if result == 32512 {
                    print()
                    print("Make sure you have the Docker Toolbox installed")
                    print("https://www.docker.com/products/docker-toolbox")
                    print("Tested with Docker Toolbox 1.11.1")
                }
                if result == 256 {
                    print()
                    print("Make sure you have the Docker daemon running")
                    print("or try running the following snippet:")
                    print("`eval \"$(docker-machine env default)\"`")
                }
                fail("Could not initialize Docker")
            } catch {
                fail("Could not initialize Docker")
            }
        }

        static var help: [String] {
            return [
                "Build the docker image, using the swift",
                "version specified in .swift-version."
            ]
        }
    }
}

extension Docker {
    struct Run: Command {
        static let id = "run"

        static func execute(with args: [String], in directory: String) {
            guard let
                imageName = Docker.imageName
                else {
                    fail("Could not determine Swift version (check your .swift-version file)")
            }

            let cmd = "docker run --rm -it -v $(PWD):/vapor -p 8080:8080 \(imageName)"
            do {
                print("Launching app with image \(imageName)")
                try run(cmd)
            } catch Error.system(let result) {
                if result == 33280 {
                    // Sven: Attempt to identify if the user has ctrl-c'd out of the container
                    // so we don't show an error in that case.
                    // Call to system returns the exit status of the shell as returned by waitpid(2).
                    // This doesn't align with 33280 which is why I'm hard-coding the value but
                    // testing showed that other means of terminating the command returns different
                    // values.
                } else {
                    fail("docker run command failed, command was\n\(cmd)")
                }
            } catch {
                fail("docker run command failed, command was\n\(cmd)")
            }
        }

        static var help: [String] {
            return [
                "Run the app in a docker container with the",
                "image created by running 'docker build'"
            ]
        }
    }
}


extension Docker {
    struct Enter: Command {
        static let id = "enter"

        static func execute(with args: [String], in directory: String) {
            guard let
                imageName = Docker.imageName
                else {
                    fail("Could not determine Swift version (check your .swift-version file)")
            }

            do {
                print("Starting bash in image \(imageName)")
                let cmd = "docker run --rm -it -v $(PWD):/vapor --entrypoint bash \(imageName)"
                try run(cmd)
            } catch Error.system(let result) {
                if result != 33280 {
                    fail("Could not enter Docker container")
                }
            } catch {
                fail("Could not enter Docker container")
            }
        }

        static var help: [String] {
            return [
                "Enter the docker container (useful for",
                "debugging purposes)"
            ]
        }
    }
}

commands.append(Docker)

// MARK: CLI

var iterator = Process.arguments.makeIterator()

guard let directory = iterator.next() else {
    fail("no directory")
}
guard let commandId = iterator.next() else {
    print("Usage: \(directory) [\(commands.map({ $0.id }).joined(separator: "|"))]")
    fail("no command")
}
guard let command = getCommand(id: commandId) else {
    fail("command \(commandId) doesn't exist")
}

command.assertDependenciesSatisfied()

let arguments = Array(iterator)
command.execute(with: arguments, in: directory)
exit(0)
