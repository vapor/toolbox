import Console
import Foundation

public final class Routes: Command {
    static let routesHelperRepo = "https://gist.github.com/6ed6db80a51ba7fa0a6383958f6dd924.git"

    public var id = "routes"
    public var signature: [Argument] = []
    public var help: [String] {
        return [
            "Prints the available routes.",
        ]
    }

    public let console: ConsoleProtocol

    public required init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let fallbackURL = URL(string: Routes.routesHelperRepo)!
        let helperFilePath = ".build/Templates/RoutesCommand/VaporRoutes.swift"
        let helperFile = try loadTemplate(atPath: helperFilePath, fallbackURL: fallbackURL)
        let mainFilePath = "Sources/App/main.swift"
        guard fileExists(atPath: mainFilePath) else {
            throw ToolboxError.general("Please run this command from the route folder of your app.")
        }
        guard fileExists(atPath: "Sources/App/Routes.swift") else {
            throw ToolboxError.general("No Routes.swift file found. Please run 'vapor generate routes' first.")
        }

        let originalMain = try File(path: mainFilePath)
        try openFile(atPath: mainFilePath) { file in
            let originalText = "drop.run()"
            let replacementText = helperFile.contents
            file.contents = file.contents.replacingOccurrences(of: originalText, with: replacementText)
        }
        try Build(console: console).run(arguments: [])
        try Run(console: console).run(arguments: ["prepare"])
        try originalMain.save() // restore main.swift to its original state
    }

}
