import Console

public final class SelfUpdate: Command {
    public let id = "update"

    public let help: [String] = [
        "Downloads and installs the latest toolbox.",
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
    }
}
