import Console

public final class SelfUpdate: Command {
    public let id = "update"

    public let help: [String] = [
        "Downloads and installs the latest toolbox.",
    ]

    public let console: ConsoleProtocol
    public let executable: String

    public init(console: ConsoleProtocol, executable: String) {
        self.console = console
        self.executable = executable
    }

    public func run(arguments: [String]) throws {
        let updateBar = console.loadingBar(title: "Updating")
        updateBar.start()
        do {
            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "curl -sL toolbox.vapor.sh | bash"])
            updateBar.finish()
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            updateBar.fail()
            throw ToolboxError.general("Could not update toolbox: \(message)")
        }
    }
}
