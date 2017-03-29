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
        let verbose = arguments.verbose
        let testBar = console.loadingBar(title: "Testing", animated: !verbose)
        testBar.start()

        do {
            let flags = try Config.testFlags()
            _ = try console.execute(verbose: verbose, program: "swift", arguments: ["test"] + flags)
            testBar.finish("Passed")
        } catch ConsoleError.backgroundExecute(_, let error, let message) {
            testBar.fail()
            console.print()
            console.info("Log:")
            console.print(error)
            console.print()
            console.info("Output:")
            console.info(message)
            console.print()
            console.info("Help:")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://vapor.team")
            console.print()

            throw ToolboxError.general("Tests failed.")
        }
    }
    
}
