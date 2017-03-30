import Console

public final class Clean: Command {
    public let id = "clean"

    public let signature: [Argument] = [
        Option(name: "xcode", help: ["Removes any Xcode projects while cleaning."]),
        Option(name: "pins", help: ["Removes the Package.pins file as well."])
    ]

    public let help: [String] = [
        "Cleans temporary files--usually fixes",
        "a plethora of bizarre build errors."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let override = console.confirmOverride ?? false
        if !override {
            console.warning("Cleaning will increase your build time ... ")
            console.warning("We recommend trying 'vapor update' first.")
            guard console.confirm("Would you like to clean anyways?") else { return }
        }

        let cleanBar = console.loadingBar(title: "Cleaning", animated: !arguments.isVerbose)
        cleanBar.start()

        _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", ".build"])

        if arguments.flag("xcode") {
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "*.xcodeproj"])
        }

        if arguments.flag("pins") {
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "Package.pins"])
        }

        cleanBar.finish()
    }
}

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
