import Foundation
import Console

public class RouteGenerator: AbstractGenerator {

    private static let routesDirectoryPath = "Sources/App/"
    private static let applicationStartFileName = "main.swift"
    private static let routesFileName = "Routes.swift"

    private static let routesOriginalText = "func configureRoutes<T : Routing.RouteBuilder>(router: T) where T.Value == HTTP.Responder {"
    private static let routesConfigOriginalText = "drop.run()"
    private static let routesConfigReplacementText = "configureRoutes(router: drop)"

    override public var id: String {
        return "route"
    }

    override public var signature: [Argument] {
        return super.signature + [
            Value(name: "method", help: ["The route's HTTP method"]),
            Option(name: "resource", help: ["Builds routes for a resource instead of the path as specified. If true, method is ignored."]),
        ]
    }

    override public func generate(arguments: [String]) throws {
        let forResource = arguments.flag("resource")
        let requiredArgumentsCount = forResource ? 1 : 2
        guard arguments.count >= requiredArgumentsCount else {
            throw ConsoleError.insufficientArguments
        }

        let path = arguments[0]
        let method = arguments[1]
        if forResource {
            try generateRoutes(forResource: path)
        }
        else {
            try generateRoute(forPath: path, method: method, handler: "JSON([:])")
        }
    }

    public func generateRoute(forPath path: String, method: String, handler: String) throws {
        console.info("Generating route '\(path)'")
        let template = try loadTemplate(atPath: defaultTemplatesDirectory + "RouteTemplate.swift",
                                        fallbackURL: URL(string: defaultTemplatesURLString)!)
        let routeText = routeString(fromTemplate: template, path: path, handler: handler, method: method)
        try addRoute(routeText)
    }

    public func generateRoutes(forResource resourceName: String) throws {
        console.info("Generating route for resource '\(resourceName.pluralized)'")
        let template = try loadTemplate(atPath: defaultTemplatesDirectory + "ResourceRoutesTemplate.swift",
                                        fallbackURL: URL(string: defaultTemplatesURLString)!)
        let routeName = resourceName.pluralized
        let handler = "\(routeName.capitalized)Controller()"
        let routeText = routeString(fromTemplate: template, path: routeName, handler: handler)
        try addRoute(routeText)
    }

    private func addRoute(_ text: String) throws {
        let originalText = RouteGenerator.routesOriginalText
        let replacementString = originalText + "\n\(text)"
        try openRoutesFile() { (file) in
            file.contents = file.contents.replacingOccurrences(of: originalText, with: replacementString)
        }
    }

    private func openRoutesFile(_ editClosure: ((inout File) -> Void)) throws {
        let filePath = try routesFilePath()
        try openFile(atPath: filePath, editClosure)
    }

    private func routesFilePath() throws -> String {
        let filePath = RouteGenerator.routesDirectoryPath + RouteGenerator.routesFileName
        guard !fileExists(atPath: filePath) else { return filePath }
        console.warning("\(filePath) not found. Creating it...")
        let template = try loadTemplate(atPath: defaultTemplatesDirectory + RouteGenerator.routesFileName,
                                        fallbackURL: URL(string: defaultTemplatesURLString)!)
        try template.saveCopy(atPath: filePath)
        try configureDropletUsingRoutesFile()
        return filePath
    }

    private func configureDropletUsingRoutesFile() throws {
        let originalText = RouteGenerator.routesConfigOriginalText
        let replacementString = RouteGenerator.routesConfigReplacementText + "\n\(originalText)"
        let filePath = RouteGenerator.routesDirectoryPath + RouteGenerator.applicationStartFileName
        try openFile(atPath: filePath) { (file) in
            file.contents = file.contents.replacingOccurrences(of: originalText, with: replacementString)
        }
    }

    private func routeString(fromTemplate template: File, path: String, handler: String, method: String = "") -> String {
        var contents = template.contents
        contents = contents.replacingOccurrences(of: "_ROUTE_", with: path)
        contents = contents.replacingOccurrences(of: "_METHOD_", with: method)
        contents = contents.replacingOccurrences(of: "_HANDLER_", with: handler)
        return contents
    }

}
