import Console

public final class Version: Command {
    public static let id = "version"
    
    public let console: Console
    public let version: String

    public init(console: Console, version: String) {
        self.console = console
        self.version = version
    }

    public func run(arguments: [String]) throws {
        console.print("Vapor CLI version: \(version)")
    }

    public var help: [String] = [
        "Displays Vapor CLI version"
    ]
}
