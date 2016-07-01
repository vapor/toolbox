
#if os(OSX)
    import Darwin
#else
    import Glibc
#endif


struct Update: Command {
    static let id = "update"

    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        guard let target = pathToSelf(in: shell) else {
            throw Error.failed("Could not determine path to vapor binary.")
        }

        let name = "vapor-install.swift"
        let quiet = args.contains("--verbose") ? "" : "-s"

        do {
            print("Downloading...")
            try shell.run("curl -L \(quiet) vapor-cli.qutheory.io -o \(name)")
        } catch {
            throw Error.failed("Could not download Vapor CLI.")
        }

        do {
            try shell.run("swift \(name) \(target)")
        } catch {
            throw Error.failed("Could not update CLI.")
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
    // this may look a bit convoluted but it's necessary to inject dependency for testing
    // Process.arguments crashes when run from unit tests
    internal static var _argumentsProvider: ArgumentsProvider.Type = Process.self

    static func pathToSelf(in shell: PosixSubsystem) -> String? {
        if let path = _argumentsProvider.arguments.first {
            if path == "vapor" {
                return (try? shell.runWithOutput("which vapor"))?.stdout?.trim()
            } else {
                return path
            }
        }
        return nil
    }
}

