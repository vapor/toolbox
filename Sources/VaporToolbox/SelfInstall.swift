import Console

public final class SelfInstall: Command {
    public let id = "install"

    public let signature: [Argument] = [
        Option(name: "path"),
    ]

    public let help: [String] = [
        "Moves the compiled toolbox to a folder.",
        "Installations default to /usr/local/bin/vapor."
    ]

    public let console: ConsoleProtocol
    public let executable: String
    let version: String

    public init(console: ConsoleProtocol, executable: String, version: String) {
        self.console = console
        self.executable = executable
        self.version = version
    }

    public func run(arguments: [String]) throws {
        let file: String
        do {
            file = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "ls \(executable)"])
        } catch ConsoleError.backgroundExecute {
            do {
                file = try console.backgroundExecute(program: "/usr/bin/which", arguments: [executable])
            } catch ConsoleError.backgroundExecute(let code, let error, _) {
                throw ToolboxError.general("Could not locate executable: \(code) \(error)")
            }
        }

        let current = file.trim()

        let command = [current, "/usr/local/bin/vapor"]
        
        do {
            _ = try console.backgroundExecute(program: "mkdir", arguments: ["-p", "/usr/local/bin"])
        } catch ConsoleError.backgroundExecute {
            console.warning("Failed to create /usr/local/bin, trying sudo")
            do {
                _ = try console.backgroundExecute(program: "sudo", arguments: ["mkdir", "-p", "/usr/local/bin"])
            } catch ConsoleError.backgroundExecute {
                throw ToolboxError.general("Installation Failed. Could not create /usr/local/bin")
            }
        }

        do {
            _ = try console.backgroundExecute(program: "mv", arguments: command)
        } catch ConsoleError.backgroundExecute {
            console.warning("Install failed, trying sudo")
            do {
                _ = try console.backgroundExecute(program: "sudo", arguments: ["mv"] + command)
            } catch ConsoleError.backgroundExecute {
                throw ToolboxError.general("Installation failed.")
            }
        }

        console.success("Vapor Toolbox v\(version) Installed")
    }
}
