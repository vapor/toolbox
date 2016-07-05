import Console

public final class Clean: Command {
    public let id = "clean"

    public let help: [String] = [
        "cleans temporary build files",
        "optionally removes generated Xcode Project"
    ]

    public let console: Console
    
    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let cleanBar = console.loadingBar(title: "Cleaning")
        cleanBar.start()

        try console.execute("rm -rf Packages .build")

        if arguments.flag("xcode") {
            try console.execute("rm -rf *.xcodeproj")
        }

        cleanBar.finish()
    }

}
