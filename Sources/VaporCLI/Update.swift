
#if os(OSX)
    import Darwin
#else
    import Glibc
#endif


struct Update: Command {
    static let id = "update"

    static func execute(with args: [String], in directory: String, shell: PosixSubsystem) {
        guard let target = pathToSelf else {
            fail("Could not determine path to vapor binary.")
        }

        let name = "vapor-install.swift"
        let quiet = args.contains("--verbose") ? "" : "-s"

        do {
            print("Downloading...")
            try run("curl -L \(quiet) vapor-cli.qutheory.io -o \(name)")
        } catch {
            fail("Could not download Vapor CLI.")
        }

        do {
            try run("swift \(name) \(target)")
        } catch {
            fail("Could not update CLI.")
        }

        print("Vapor CLI updated.")
    }
}


extension Update {
    static var help: [String] {
        return [
            "Downloads and installs the latest version ",
            "of the Vapor command line interface",
        ]
    }
}


extension Update {
    static var pathToSelf: String? {
        if let path = Process.arguments.first {
            if path == "vapor" {
                return try? runWithOutput("which vapor").trim()
            } else {
                return path
            }
        }
        return nil
    }
}

