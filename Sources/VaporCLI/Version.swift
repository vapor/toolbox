import Console

public final class Version: Command {
    public let id = "version"

    public let help: [String] = [
        "Displays Vapor CLI version"
    ]

    public let console: Console
    public let version: String

    public init(console: Console, version: String) {
        self.console = console
        self.version = version
    }

    public func run(arguments: [String]) throws {
        console.print("Vapor Toolbox v\(version)")

        do {
            let run = Run(console: console)
            try run.run(arguments: ["version"])
        } catch Error.general(_) {
            console.warning("Cannot print Vapor Framework version, no project found.")
        }
    }

}
