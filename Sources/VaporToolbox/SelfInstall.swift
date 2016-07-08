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

    public init(console: Console, executable: String) {
        self.console = console
        self.executable = executable
    }

    public func run(arguments: [String]) throws {
        let file: String
        do {
            file = try console.executeInBackground("ls \(executable)")
        } catch ConsoleError.execute(_) {
            do {
                file = try console.executeInBackground("which \(executable)")
            } catch ConsoleError.execute(_) {
                throw Error.general("Could not locate executable.")
            }
        }

        let current = String(file.characters.dropLast())

        let command = "mv \(current) /usr/local/bin/vapor"
        do {
            try console.executeInForeground(command)
        } catch ConsoleError.execute(_) {
            console.warning("Install failed, trying sudo")
            do {
                try console.executeInForeground("sudo \(command)")
            } catch ConsoleError.execute(_) {
                throw Error.general("Installation failed.")
            }
        }
    }
}
