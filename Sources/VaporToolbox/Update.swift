import Console

public final class Update: Command {
    public let id = "update"

    public let signature: [Argument] = [
        Option(name: "xcode", help: ["Removes any Xcode projects while cleaning."])
    ]

    public let help: [String] = [
        "Updates your dependencies."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let isVerbose = arguments.isVerbose
        let bar = console.loadingBar(title: "Updating", animated: !isVerbose)
        bar.start()
        try console.execute(verbose: isVerbose, program: "swift", arguments: ["package", "update"])
        bar.finish()

        #if !os(Linux)
            console.info("Changes to dependencies usually require Xcode to be regenerated.")
            let shouldGenerateXcode = console.confirm("Would you like to regenerate your xcode project now?")
            guard shouldGenerateXcode else { return }
            let xcode = Xcode(console: console)
            try xcode.run(arguments: arguments)
        #endif
    }
}
