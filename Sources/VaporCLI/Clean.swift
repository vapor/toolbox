import Console

public final class Clean: Command {
    public static let id = "clean"
    
    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {

        try console.execute("rm -rf Packages .build")

        if arguments.flag("xcode") {
            try console.execute("rm -rf *.xcodeproj")
        }

        console.success("Cleaned.")
    }

    public let help: [String] = [
        "cleans temporary build files",
        "optionally removes generated Xcode Project"
    ]
}
