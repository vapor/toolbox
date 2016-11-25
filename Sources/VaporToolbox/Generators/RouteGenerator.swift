import Foundation
import Console

public class RouteGenerator: AbstractGenerator {

    private static let routesFilePath = "Sources/App/main.swift"

    override public var id: String {
        return "route"
    }

    override public var signature: [Argument] {
        return super.signature + [
            Value(name: "method", help: ["The route's HTTP method"]),
            Value(name: "handler", help: ["A string representing code to get a ResponseRepresentable value to handle the route response"]),
            Option(name: "resource", help: ["Builds routes for a resource instead of the path as specified. If true, method is ignored."]),
        ]
    }

    override public func generate(arguments: [String]) throws {
        let forResource = arguments.flag("resource")
        let requiredArgumentsCount = forResource ? 1 : 3
        guard arguments.count >= requiredArgumentsCount else {
            throw ConsoleError.insufficientArguments
        }

        let path = arguments[0]
        let method = arguments[1]
        if forResource {
            try generateRoutes(forResource: path)
        }
        else {
            try generateRoute(forPath: path, method: method, handler: arguments[3])
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
        let originalText = "\ndrop.run()"
        let replacementString = "\(text)\n\(originalText)"
        try openRoutesFile() { (file) in
            file.contents = file.contents.replacingOccurrences(of: originalText, with: replacementString)
        }
    }

    private func openRoutesFile(_ editClosure: ((inout File) -> Void)) throws {
        let filePath = RouteGenerator.routesFilePath
        try checkThatFileExists(atPath: filePath)
        var file = try File(path: filePath)
        editClosure(&file)
        try file.save()
    }

    private func routeString(fromTemplate template: File, path: String, handler: String, method: String = "") -> String {
        var contents = template.contents
        contents = contents.replacingOccurrences(of: "_ROUTE_", with: path)
        contents = contents.replacingOccurrences(of: "_METHOD_", with: method)
        contents = contents.replacingOccurrences(of: "_HANDLER_", with: handler)
        return contents
    }

}
