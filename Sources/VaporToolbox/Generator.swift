import Foundation
import Console

public protocol FileProtocol {
    var path: String { get }
    var name: String { get }
    var directory: String { get }
}

extension FileProtocol {

    public var name: String {
        return path.components(separatedBy: "/").last!
    }

    public var directory: String {
        var components = path.components(separatedBy: "/")
        components.removeLast()
        return components.joined(separator: "/")
    }

}

public struct File: FileProtocol {
    public let path: String
    public var contents: String

    public init(path: String) throws {
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        self.init(path: path, contents: contents)
    }

    public init(path: String, contents: String) {
        self.path = path
        self.contents = contents
    }

    public func save() throws {
        try saveCopy(atPath: path)
    }

    public func saveCopy(atPath path: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

public struct FileTemplate: FileProtocol {
    private static let defaultURLString = "https://gist.github.com/1b9b58c0ca4dbe3538b2707df5959d80.git"

    public let path: String
    public let source: URL

    public init(path: String, source: URL? = nil) {
        self.path = path
        self.source = source ?? URL(string: FileTemplate.defaultURLString)!
    }
}

public protocol Generator {
    static var supportedTypes: [String] { get }
    var console: ConsoleProtocol { get }

    init(console: ConsoleProtocol)
    func generate(arguments: [String : String]) throws
}

public extension Generator {

    public func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    public func checkThatFileExists(atPath path: String) throws {
        guard fileExists(atPath: path) else {
            throw ToolboxError.general("\(path) not found.")
        }
    }

    public func checkThatFileDoesNotExist(atPath path: String) throws {
        guard !fileExists(atPath: path) else {
            throw ToolboxError.general("\(path) already exists")
        }
    }

    public func generateFile(named fileName: String, inside directoryPath: String, template: FileTemplate) throws -> File {
        try checkThatFileExists(atPath: directoryPath)
        let filePath = "\(directoryPath)/\(fileName)"
        try checkThatFileDoesNotExist(atPath: filePath)
        console.info("Generating \(filePath)")
        if !fileExists(atPath: template.path) {
            try cloneTemplate(template)
        }
        return try File(path: template.path)
    }

    private func cloneTemplate(_ template: FileTemplate) throws {
        let destination = template.directory
        let cloneBar = console.loadingBar(title: "Cloning Template")
        cloneBar.start()
        do {
            _ = try console.backgroundExecute(program: "git", arguments: ["clone", "\(template.source)", "\(destination)"])
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "\(destination)/.git"])
            cloneBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            cloneBar.fail()
            throw ToolboxError.general(error.string.trim())
        }
    }

}

public extension String {

    public var pluralized: String {
        // dumb but effective for what I need
        // TODO: make this smarter
        return characters.last == "s" ? self : self + "s"
    }

}
