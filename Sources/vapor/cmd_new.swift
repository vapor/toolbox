#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

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

