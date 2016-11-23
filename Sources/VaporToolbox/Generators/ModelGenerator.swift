import Console

public final class ModelGenerator: Generator {

    public static let supportedTypes = ["model"]
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String : String]) throws {
        guard let name = arguments["name"] else {
            throw ConsoleError.argumentNotFound
        }
        let directory = "Sources/App/Models"
        let fileName = name.capitalized + ".swift"
        let templatePath = ".build/Templates/ModelTemplate.swift"
        let template = FileTemplate(path: templatePath)
        var file = try generateFile(named: fileName, inside: directory, template: template)
        file.contents = file.contents.replacingOccurrences(of: "_CLASS_NAME_", with: name.capitalized)
        file.contents = file.contents.replacingOccurrences(of: "_IVAR_NAME_", with: name.lowercased())
        file.contents = file.contents.replacingOccurrences(of: "_TABLE_NAME_", with: name.pluralized)
        try file.saveCopy(atPath: "\(directory)/\(fileName)")
    }

}
