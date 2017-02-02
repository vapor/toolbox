import Foundation
import Console

open class AbstractGenerator: Command, Generator {
    open var id: String {
        return "generator" // override me
    }

    open var signature: [Argument] {
        return [
            Value(name: "name", help: ["The resource name"]),
            Option(name: "xcode", help: ["Rebuilds the Xcode project when done"]),
        ]
    }

    open var help: [String] {
        return [
            "Helper to generate Vapor classes.",
        ]
    }

    public let console: ConsoleProtocol

    public required init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        guard FileManager.default.fileExists(atPath: "Sources/App/") else {
            throw ToolboxError.general("Please run this command from your project's root folder.")
        }
        // Remove the generator type from the arguments.
        // There seems to be a bug in Console.Group for which the invoked action id is passed as argument.
        let passedOnArguments = Array(arguments[1 ..< arguments.count])
        try generate(arguments: passedOnArguments)
        if arguments.flag("xcode") {
            let projectGenerator = Xcode(console: console)
            try projectGenerator.run(arguments: [])
        }
        console.success("All done")
    }

    open func generate(arguments: [String]) throws {
        throw ToolboxError.general("'\(String(describing: AbstractGenerator.self))' is meant to be subclassed.")
    }

}
