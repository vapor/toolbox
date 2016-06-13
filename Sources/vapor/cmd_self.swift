
#if os(OSX)
    import Darwin
#else
    import Glibc
#endif


extension SelfCommands {
    static func install(from: String, to: String) throws {
        do {
            try run("chmod +x \(from)")
            try run("mv \(from) \(to)")
        } catch {
            try run("sudo mv \(from) \(to)")
        }
    }
}

extension SelfCommands {
    struct Update: Command {
        static let id = "update"

        static func execute(with args: [String], in directory: String) {
            guard let target = pathToSelf else {
                fail("Could not determine path to script.")
            }

            let name = "vapor-cli.tmp"
            let quiet = args.contains("--verbose") ? "" : "-s"

            do {
                print("Downloading...")
                try run("curl -L \(quiet) cli.qutheory.io -o \(name)")
            } catch {
                fail("Could not download Vapor CLI.")
            }

            do {
                try SelfCommands.install(from: name, to: target)
            } catch {
                fail("Could not update CLI.")
            }

            print("Vapor CLI updated.")

            do {
                try run("\(target) self compile")
            } catch {
                fail("Could not compile Vapor CLI.")
            }
        }

        static var help: [String] {
            return [
                "Downloads the latest version of",
                "the Vapor command line interface",
                "and compiles it into a binary."
            ]
        }
    }
}


// FIXME: Sven: this command is obsolete in the SPM built version. Keeping it in for the moment to make merges from master easier and will remove once it's clear this will be merged next. The whole install process needs some tweaking for SPM based installs (d/l bootstrap.swift + running it)
extension SelfCommands {
    struct Compile: Command {
        static let id = "compile"

        static func execute(with args: [String], in directory: String) {
            guard let target = pathToSelf else {
                fail("Could not determine path to script.")
            }
            guard !SelfCommands.isCompiled(path: target) else {
                print("Script is already compiled") // don't use fail as it's not really an error
                return
            }

            let tmp = "vapor-cli.swift"

            do {
                try run("cp \(target) \(tmp)")
            } catch {
                fail("Could not copy source.")
            }

            print("Compiling...")

            let name = "vapor-cli.tmp"
            let compile = "swiftc \(tmp) -o \(name)"
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
                try SelfCommands.install(from: name, to: target)
            } catch {
                fail("Could not install compiled binary at '\(target)'")
            }

            do {
                try run("rm \(tmp)")
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

    static func isCompiled(path: String) -> Bool {
        let cmd = "file \(path) | grep 'text executable' > /dev/null 2>&1"
        return system(cmd) != 0
    }

    static var subCommands: [Command.Type] = [
        SelfCommands.Update.self,
        SelfCommands.Compile.self
    ]

    static func execute(with args: [String], in directory: String) {
        executeSubCommand(with: args, in: directory)
    }
}

