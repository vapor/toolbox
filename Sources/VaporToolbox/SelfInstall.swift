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
            file = try console.backgroundExecute(program: "ls", arguments: ["\(executable)"])
        } catch ConsoleError.execute(_) {
            do {
                file = try console.backgroundExecute(program: "which", arguments: ["\(executable)"])
            } catch ConsoleError.execute(_) {
                throw ToolboxError.general("Could not locate executable.")
            }
        }

        let current = file.trim()

        let commandArray = ["mv", "\(current)", "/usr/local/bin/vapor"]
        do {
            _ = try console.backgroundExecute(program: commandArray[0], arguments: commandArray.dropFirst(1).array)
        } catch ConsoleError.backgroundExecute(_) {
            console.warning("Install failed, trying sudo")
            do {
                _ = try console.backgroundExecute(program: "sudo", arguments: commandArray)
            } catch ConsoleError.backgroundExecute(_) {
                throw ToolboxError.general("Installation failed.")
            }
        }

        console.success("Vapor Toolbox v\(version) Installed")
    }
}
