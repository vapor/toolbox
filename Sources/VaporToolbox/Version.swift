import Console

/*
 robo:vapor.git-5492988889259800272 logan$ git describe --exact-match --tags HEAD
 2.0.0-beta.1
 */

public final class Version: Command {
    public let id = "version"

    public let help: [String] = [
        "Displays Vapor CLI version"
    ]

    public let console: ConsoleProtocol
    public let version: String

    public init(console: ConsoleProtocol, version: String) {
        self.console = console
        self.version = version
    }

    public func run(arguments: [String]) throws {
        console.print("Vapor Toolbox v\(version)")

        do {
            let run = Run(console: console)
            try run.run(arguments: ["version"])
        } catch ToolboxError.general(_) {
            console.warning("Cannot print Vapor Framework version, no project found.")
        }
    }

}
