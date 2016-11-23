import Console

public final class ViewGenerator: Generator {

    public static let supportedTypes = ["view"]
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String : String]) throws {
        // let treatAsResource = arguments["treatAsResource"] ?? "false"
        // let viewsFolderPath = "Resources/Views"
        // try checkThatFileExists(atPath: viewsFolderPath, console: console)
        // let resourceFlag = "--resource=\(treatAsResource)"
        console.error("TODO: Generating views...")
    }

}
