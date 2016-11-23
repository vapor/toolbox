import Console

public final class ControllerGenerator: Generator {

    public static let supportedTypes = ["controller"]
    private let directory = "Sources/App/Controllers"
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String : String]) throws {
        guard let name = arguments["name"] else {
            throw ConsoleError.argumentNotFound
        }
        let resourceName = name.capitalized
        let className = resourceName.pluralized
        let fileName = resourceName + "Controller.swift"
        try copyTemplate(named: "ControllerTemplate.swift", withName: fileName) { (file) in
            var contents = file.contents.replacingOccurrences(of: "_CLASS_NAME_", with: className)
            contents = contents.replacingOccurrences(of: "_RESOURCE_NAME_", with: resourceName)
            contents = contents.replacingOccurrences(of: "_VAR_NAME_", with: name.lowercased())
            return File(path: file.path, contents: contents)
        }
        if !fileExists(atPath: "\(directory)/ApplicationController.swift") {
            try copyTemplate(named: "ApplicationController.swift")
        }
        // TODO: support resource actions
    }

    private func copyTemplate(named templateName: String, withName fileName: String? = nil, _ editClosure: ((File) -> File)? = nil) throws {
        let templatePath = ".build/Templates/\(templateName)"
        let template = FileTemplate(path: templatePath)
        let name = fileName ?? templateName
        let templateFile = try generateFile(named: name, inside: directory, template: template)
        let file = editClosure?(templateFile) ?? templateFile
        try file.saveCopy(atPath: "\(directory)/\(name)")
    }

}
