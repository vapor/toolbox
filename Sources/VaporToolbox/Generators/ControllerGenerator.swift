import Foundation
import Console

public final class ControllerGenerator: AbstractGenerator {

    private let controllersDirectory = "Sources/App/Controllers/"
    private let scriptsDirectory = "Public/scripts/"
    private let stylesDirectory = "Public/styles/"

    override public var id: String {
        return "controller"
    }

    override public var signature: [Argument] {
        return super.signature + [
            Value(name: "actions", help: ["An optional list of actions. Routes and Views will be created for each action."]),
            Option(name: "resource", help: ["Builds controller for a resource"]),
            Option(name: "no-css", help: ["If true it doen't create a CSS file for the controller, defaults to true if 'actions' is empty."]),
            Option(name: "no-js", help: ["If true it doen't create a JavsScript file for the controller, defaults to true if 'actions' is empty."]),
        ]
    }

    override public func generate(arguments: [String]) throws {
        guard let name = arguments.first?.lowercased() else {
            throw ConsoleError.argumentNotFound
        }

        let argumentsWithoutName = Array(arguments.values[1 ..< arguments.values.count])
        let actions = argumentsWithoutName.filter { return !$0.contains(":") }
        console.print("Controller actions => \(actions)")

        if arguments.flag("resource") {
            try generateResourcesController(forResourceNamed: name, actions: actions)
        }
        else {
            try generateSimpleController(named: name, actions: actions)
        }

        try generateViews(forActions: actions, resourceName: name)
        if actions.count > 0 {
            try generatePublicResources(arguments: arguments, resourceName: name)
        }
        // TODO: generate test class
    }

    public func generateResourcesController(forResourceNamed resourceName: String, actions: [String]) throws {
        try generateApplicationControllerIfNeeded()
        let file = try generateController(named: resourceName, templateName: "ControllerTemplate.swift")
        try uncommentMethods(forActions: actions, inFile: file)
        try generateRoutes(forResource: resourceName)
    }

    private func generateSimpleController(named name: String, actions: [String]) throws {
        try generateController(named: name, templateName: "ControllerTemplateSimple.swift")
        try generateRoutes(forActions: actions, resourceName: name)
    }

    @discardableResult
    private func generateController(named name: String, templateName: String) throws -> File {
        let className = ControllerGenerator.controllerNameForResource(name)
        let filePath = "\(controllersDirectory)\(className).swift"
        let templatePath = defaultTemplatesDirectory + templateName
        let fallbackURL = URL(string: defaultTemplatesURLString)!
        try copyTemplate(atPath: templatePath, fallbackURL: fallbackURL, toPath: filePath) { (contents) in
            var newContents = contents
            newContents = newContents.replacingOccurrences(of: "_CLASS_NAME_", with: className)
            newContents = newContents.replacingOccurrences(of: "_RESOURCE_NAME_", with: name.capitalized)
            newContents = newContents.replacingOccurrences(of: "_VAR_NAME_", with: name.lowercased())
            return newContents
        }
        return try File(path: filePath)
    }

    private func generateApplicationControllerIfNeeded() throws {
        let fileName = "ApplicationController.swift"
        let applicationControllerPath = controllersDirectory + fileName
        if !fileExists(atPath: applicationControllerPath) {
            console.warning("ApplicationController not found. Creating it...")
            let applicationControllerTemplatePath = defaultTemplatesDirectory + fileName
            try copyTemplate(atPath: applicationControllerTemplatePath,
                fallbackURL: URL(string: defaultTemplatesURLString)!,
                toPath: applicationControllerPath)
        }
    }

    private func generateViews(forActions actions: [String], resourceName: String) throws {
        let viewGenerator = ViewGenerator(console: console)
        try viewGenerator.generateViews(forResourceNamed: resourceName, actions: actions)
    }

    private func generatePublicResources(arguments: [String], resourceName: String) throws {
        var resourcesToGenerate: [String] = []
        if !arguments.flag("no-css") {
            resourcesToGenerate.append(stylesDirectory + "\(resourceName.pluralized).css")
        }
        if !arguments.flag("no-js") {
            resourcesToGenerate.append(scriptsDirectory + "\(resourceName.pluralized).js")
        }
        for path in resourcesToGenerate {
            console.info("Generating \(path)")
            try File(path: path, contents: "").save()
        }
    }

    private func uncommentMethods(forActions actions: [String], inFile file: File) throws {
        var string = file.contents
        var rangesToRemove: [Range<String.CharacterView.Index>] = []

        for action in actions {
            var openingRange: Range<String.CharacterView.Index>?
            var shouldCloseRange = false
            let searchRange = string.startIndex ..< string.endIndex
            string.enumerateSubstrings(in: searchRange, options: .byLines) { (substring, _, range, stop) in
                guard let substring = substring else { stop = true; return }
                if substring.contains("/*") {
                    openingRange = range
                }
                if substring.contains("func \(action)") {
                    shouldCloseRange = true
                }
                if let openingRange = openingRange, shouldCloseRange && substring.contains("*/") {
                    rangesToRemove.append(openingRange)
                    rangesToRemove.append(range)
                    stop = true
                }
            }

            if let range = string.range(of: "\(action): nil, // \(action)") {
                string.replaceSubrange(range, with: "\(action): \(action)")
            }
        }

        // as indexes are invalidated on subrange removal,
        // by reversing the array of ranges we keep the indexes we're working on valid
        for range in rangesToRemove.reversed() {
            string.removeSubrange(range)
        }

        // save changes
        try File(path: file.path, contents: string).save()
    }

    private func generateRoutes(forActions actions: [String], resourceName: String) throws {
        let routeGenerator = RouteGenerator(console: console)
        let controllerName = ControllerGenerator.controllerNameForResource(resourceName)
        for action in actions {
            let path = "\(resourceName.pluralized.lowercased())/\(action)"
            let handler = "try \(controllerName)().render(\"\(action)\")"
            try routeGenerator.generateRoute(forPath: path, method: "get", handler: handler)
        }
    }

    private func generateRoutes(forResource resourceName: String) throws {
        try RouteGenerator(console: console).generateRoutes(forResource: resourceName)
    }

    private class func controllerNameForResource(_ name: String) -> String {
        let resourceName = name.capitalized
        let className = resourceName.pluralized + "Controller"
        return className
    }

}
