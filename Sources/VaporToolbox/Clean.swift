import Console

public final class Clean: Command {
    public let id = "clean"

    public let signature: [Argument] = [
        Option(name: "xcode", help: ["Removes any Xcode projects while cleaning."])
    ]

    public let help: [String] = [
        "Cleans temporary files--usually fixes",
        "a plethora of bizarre build errors."
    ]

    public let console: Console
    
    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let cleanBar = console.loadingBar(title: "Cleaning")
        cleanBar.start()

        _ = try console.subexecute("rm -rf Packages .build")

        if arguments.flag("xcode") {
            _ = try console.subexecute("rm -rf *.xcodeproj")
        }

        cleanBar.finish()
    }

}
