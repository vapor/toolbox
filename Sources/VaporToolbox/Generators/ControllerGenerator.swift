import Foundation
import Console

public final class ControllerGenerator: Generator {

    private let controllersDirectory = "Sources/App/Controllers/"
    private let templatesDirectory = ".build/Templates/"
    private let stylesDirectory = "Public/styles/"

    public static let supportedTypes = ["controller"]
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        let actions = Array(arguments.values[1 ..< arguments.values.count]).filter { return !$0.contains(":") }
        console.print("Controller actions => \(actions)")
        try generateController(forResourceNamed: name.lowercased(), actions: actions)
    }

    public func generateController(forResourceNamed resourceName: String, actions: [String]) throws {
        try generateController(forResourceNamed: resourceName)
        try generateApplicationControllerIfNeeded()
        // TODO: generate resource actions
        // TODO: generate test class
        if actions.count > 0 {
            let viewGenerator = ViewGenerator(console: console)
            try viewGenerator.generateViews(forResourceNamed: resourceName, actions: actions)
            try File(path: stylesDirectory + "\(resourceName.css)", contents: "").save()
        }
    }

    private func generateController(forResourceNamed name: String) throws {
        let resourceName = name.capitalized
        let className = resourceName.pluralized + "Controller"
        let filePath = "\(controllersDirectory)\(className).swift"
        let templatePath = templatesDirectory + "ControllerTemplate.swift"
        let fallbackURL = URL(string: defaultTemplatesURLString)!
        try copyTemplate(atPath: templatePath, fallbackURL: fallbackURL, toPath: filePath) { (contents) in
            var newContents = contents
            newContents = newContents.replacingOccurrences(of: "_CLASS_NAME_", with: className)
            newContents = newContents.replacingOccurrences(of: "_RESOURCE_NAME_", with: resourceName)
            newContents = newContents.replacingOccurrences(of: "_VAR_NAME_", with: resourceName.lowercased())
            return newContents
        }
    }

    private func generateApplicationControllerIfNeeded() throws {
        let fileName = "ApplicationController.swift"
        let applicationControllerPath = controllersDirectory + fileName
        if !fileExists(atPath: applicationControllerPath) {
            let applicationControllerTemplatePath = templatesDirectory + fileName
            try copyTemplate(atPath: applicationControllerTemplatePath,
                             fallbackURL: URL(string: defaultTemplatesURLString)!,
                             toPath: applicationControllerPath)
        }
    }

}
