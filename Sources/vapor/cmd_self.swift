
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

