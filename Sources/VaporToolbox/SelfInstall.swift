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

    public let console: Console
    public let executable: String
    let version: String

    public init(console: Console, executable: String, version: String) {
        self.console = console
        self.executable = executable
        self.version = version
    }

    public func run(arguments: [String]) throws {
        let file: String
        do {
            file = try console.subexecute("ls \(executable)")
        } catch ConsoleError.execute(_) {
            do {
                file = try console.subexecute("which \(executable)")
            } catch ConsoleError.execute(_) {
                throw Error.general("Could not locate executable.")
            }
        }

        let current = String(file.characters.dropLast())

        let command = "mv \(current) /usr/local/bin/vapor"
        do {
            _ = try console.subexecute(command)
        } catch ConsoleError.subexecute(_) {
            console.warning("Install failed, trying sudo")
            do {
                _ = try console.subexecute("sudo \(command)")
            } catch ConsoleError.subexecute(_) {
                throw Error.general("Installation failed.")
            }
        }

        console.success("Vapor Toolbox v\(version) Installed")
    }
}
