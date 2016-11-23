import Console

public final class ResourceGenerator: Generator {
    public static let supportedTypes = ["resource"]
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String : String]) throws {
        guard let name = arguments["name"] else {
            throw ConsoleError.argumentNotFound
        }

        let viewGenerator = ViewGenerator(console: console)
        try viewGenerator.generate(arguments: arguments)

        let modelGenerator = ModelGenerator(console: console)
        try modelGenerator.generate(arguments: arguments)

        let controllerGenerator = ControllerGenerator(console: console)
        try controllerGenerator.generate(arguments: arguments)

        try addRouteResourceForResource(named: name)
    }

    private func addRouteResourceForResource(named resourceName: String) throws {
        let filePath = "Sources/App/main.swift"
        guard fileExists(atPath: filePath) else {
            throw ToolboxError.general("Error: main.swift doesn't exist.")
        }
        console.info("Adding route for resource '\(resourceName.pluralized)' to \(filePath)")
        var file = try File(path: filePath)
        let routeName = resourceName.pluralized
        let controllerName = "\(routeName.capitalized)Controller()"
        let originalText = "\ndrop.run()"
        let replacementString = "drop.resource(\"\(routeName)\", \(controllerName))\n\(originalText)"
        file.contents = file.contents.replacingOccurrences(of: originalText, with: replacementString)
        try file.save()
    }
}
