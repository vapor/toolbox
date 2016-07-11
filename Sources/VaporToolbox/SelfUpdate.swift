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
        let updateBar = console.loadingBar(title: "Updating")
        updateBar.start()
        do {
            _ = try console.subexecute("curl -sL toolbox.qutheory.io | bash")
            updateBar.finish()
        } catch ConsoleError.subexecute(_, let message) {
            updateBar.fail()
            throw Error.general("Could not update toolbox: \(message)")
        }
    }
}
