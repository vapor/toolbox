#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

struct New: Command {
    static let id = "new"

    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        guard let name = args.first else {
            print("Usage: \(VaporCLI.id) \(id) <project-name>")
            throw Error.failed("Invalid number of arguments.")
        }

        let verbose = args.contains("--verbose")
        let curlArgs = verbose ? "" : "-s"
        let tarArgs = verbose ? "v" : ""

        do {
            let escapedName = "\"\(name)\"" // FIX: Doesn’t support names with quotes
            try shell.run("mkdir \(escapedName)")

            print("Cloning example...")

            try shell.run("curl -L \(curlArgs) https://github.com/qutheory/vapor-example/archive/master.tar.gz -o \(escapedName)/vapor-example.tar.gz")

            print("Unpacking...")

            try shell.run("tar -\(tarArgs)xzf \(escapedName)/vapor-example.tar.gz --strip-components=1 --directory \(escapedName)")
            try shell.run("rm \(escapedName)/vapor-example.tar.gz")
            #if os(OSX)
                try shell.run("cd \(escapedName) && vapor xcode")
            #endif

            if shell.commandExists("git") {
                print("Initializing git repository if necessary...")
                try shell.run("git init \(escapedName)")
                try shell.run("cd \(escapedName) && git add . && git commit -m \"initial vapor project setup\"")
                print()
            }

            print()
            shell.printFancy(asciiArt)
            print()
            shell.printFancy([
                "    Project \"\(name)\" has been created.",
                "Type `cd \(name)` to enter project directory",
                "                   Enjoy!",
                ])
            print()
            #if os(OSX)
                try shell.run("open \(escapedName)/*.xcodeproj")
            #endif
        } catch {
            throw Error.failed("Could not clone repository")
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

