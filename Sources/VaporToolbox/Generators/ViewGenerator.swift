import Foundation
import Console

public final class ViewGenerator: AbstractGenerator {

    private static let viewsFolderPath = "Resources/Views"

    override public var id: String {
        return "view"
    }

    override public func generate(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        try generateView(atPath: "\(ViewGenerator.viewsFolderPath)/\(name).leaf")
    }

    internal func generateViews(forResourceNamed resourceName: String, actions: [String]) throws {
        let path = "\(ViewGenerator.viewsFolderPath)/\(resourceName.pluralized)"
        console.info("Generating directory \(path)")
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        if actions.isEmpty {
            let gitKeep = File(path: path + "/.gitkeep", contents: "")
            try gitKeep.save()
        }
        for action in actions {
            try generateView(atPath: "\(path)/\(action).leaf")
        }
    }

    private func generateView(atPath path: String) throws {
        try copyTemplate(atPath: defaultTemplatesDirectory + "ViewTemplate.leaf",
                         fallbackURL: URL(string: defaultTemplatesURLString)!,
                         toPath: path)
    }

}
