import Console

public final class Test: Command {
    public let id = "test"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Runs the application's tests."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let testBar = console.loadingBar(title: "Testing")
        testBar.start()

        do {
            _ = try console.backgroundExecute(program: "swift", arguments: ["test"])
            testBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            testBar.fail()
            console.print()
            console.info("Log:")
            console.print(error.string)
            console.print()
            console.info("Help:")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://vapor.team")
            console.print()

            throw ToolboxError.general("Tests failed.")
        }
    }
    
}
