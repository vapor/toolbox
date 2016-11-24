import Foundation
import Console

public final class Generate: Command {
    public let id = "generate"
    public let signature: [Argument] = [
        Value(name: "type", help: ["The generator type [view|model|controller|resource]"]),
        Value(name: "name", help: ["The resource name"]),
        Option(name: "xcode", help: ["Rebuilds the Xcode project when done"]),
    ]
    public let help: [String] = [
        "Helper to generate Vapor classes.",
    ]

    public let console: ConsoleProtocol

    private static let generatorClasses: [Generator.Type] = [
        ViewGenerator.self,
        ModelGenerator.self,
        ControllerGenerator.self,
        ResourceGenerator.self
    ]

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        try generate(arguments: arguments)
        if arguments.flag("xcode") {
            let projectGenerator = Xcode(console: console)
            try projectGenerator.run(arguments: [])
        }
        console.success("All done")
    }

    func generate(arguments: [String]) throws {
        guard FileManager.default.fileExists(atPath: "Sources/App/") else {
            throw ToolboxError.general("Please run this command from your project's root folder.")
        }

        let type = try value("type", from: Array(arguments.values)) as! String
        let name = try value("name", from: Array(arguments.values)) as! String
        let passedOnArguments = Array(arguments[1 ..< arguments.count])
        var didGenerate = false

        for generatorClass in Generate.generatorClasses {
            if generatorClass.supportedTypes.contains(type) {
                didGenerate = true
                let generator = generatorClass.init(console: console)
                try generator.generate(arguments: passedOnArguments)
            }
        }

        guard didGenerate else {
            throw ToolboxError.general("Unrecognized generator type '\(type)'.")
        }
        console.success("\(type.capitalized) '\(name)' successfully generated")
    }

}
