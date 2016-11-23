import Foundation
import Console

// TODO: load generators from Generators folder and dynamically decide which to use

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

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let type = try value("type", from: Array(arguments.values)) as! String
        let name = try value("name", from: Array(arguments.values)) as! String
        try generate(arguments: ["type": type, "name": name])
        console.success("\(type.capitalized) '\(name)' successfully generated")
        if arguments.flag("xcode") {
            let projectGenerator = Xcode(console: console)
            try projectGenerator.run(arguments: [])
        }
        console.success("All done")
    }

    func generate(arguments: [String : String]) throws {
        guard FileManager.default.fileExists(atPath: "Sources/App/") else {
            throw ToolboxError.general("Please run this command from your project's root folder.")
        }

        guard let type = arguments["type"] else {
            throw ConsoleError.argumentNotFound
        }

        let generatorClasses: [Generator.Type] = [
            ViewGenerator.self,
            ModelGenerator.self,
            ControllerGenerator.self,
            ResourceGenerator.self
        ]

        var didGenerate = false
        for generatorClass in generatorClasses {
            if generatorClass.supportedTypes.contains(type) {
                didGenerate = true
                let generator = generatorClass.init(console: console)
                try generator.generate(arguments: arguments)
            }
        }

        guard didGenerate else {
            throw ToolboxError.general("Unrecognized generator type '\(type)'.")
        }
    }

}
