import Foundation
import Console

let preparationsFolder = "./Sources/App/Preparations"
let preparationListFile = "Preparations.swift"

struct PreparationFile {
    let name: String
    var timestamp: String

    init(name: String) {
        self.name = "Preparation\(name)"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        timestamp = formatter.string(from: Date())
    }

    init?(filename: String) {
        let parts = filename.replacingOccurrences(of: ".swift", with: "").components(separatedBy: "_")
        print(parts)
        guard parts.count > 2 else {
            return nil
        }
        timestamp = parts.prefix(through: 1).joined(separator: "_")
        name = parts.suffix(from: 2).joined(separator: "_")
    }

    var filename: String {
        return "\(timestamp)_\(name).swift"
    }

    var filepath: String {
        return "\(preparationsFolder)/\(filename)"
    }
}

struct PreparationManager {
    func loadPreparations(console: ConsoleProtocol) throws -> [PreparationFile] {
        do {
            let preparations = try console.backgroundExecute(program: "ls", arguments: [preparationsFolder])
            return preparations.components(separatedBy: CharacterSet.newlines).flatMap {
                return PreparationFile(filename: $0)
            }
        } catch ConsoleError.backgroundExecute(_) {
            console.warning("No preparations folder found (\(preparationsFolder)).")
        }

        return []
    }
}

public final class PrepareAdd: Command {
    public let id = "add"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Create new database preparation file."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        var preparationFile = try makePreparationFile(arguments: arguments)
        try verifyVaporApp()
        try verifyPreparationsFolder(preparationFile: preparationFile)
        preparationFile = try generateNewPreparation(preparationFile: preparationFile)
        try generatePreparationsListFile()
        try runXcodeCommand()
    }

    private func makePreparationFile(arguments: [String]) throws -> PreparationFile {
        guard arguments.count > 1 else {
            throw ToolboxError.general("Missing preparation name. Usage: vapor prepare add MyPreparation")
        }
        return PreparationFile(name: arguments[1])
    }

    private func verifyVaporApp() throws {
        do {
            _ = try console.backgroundExecute(program: "ls", arguments: ["./Sources/App/main.swift"])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("Invalid Vapor template: could not find Sources/App/main.swift file")
        }
    }

    private func verifyPreparationsFolder(preparationFile: PreparationFile) throws {
        do {
            _ = try console.backgroundExecute(program: "ls", arguments: [preparationsFolder])
            return
        } catch ConsoleError.backgroundExecute(_) {
            console.warning("No preparations folder found (\(preparationsFolder)). Creating now...")
        }

        do {
            _ = try console.backgroundExecute(program: "mkdir", arguments: ["-p", preparationsFolder])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("Failed to create preparations folder (\(preparationsFolder)).")
        }
    }

    private func generateNewPreparation(preparationFile: PreparationFile) throws -> PreparationFile {
        do {
            let template = preparationTemplate(preparationFile: preparationFile)
            try template.write(toFile: preparationFile.filepath, atomically: true, encoding: .utf8)
        } catch {
            throw ToolboxError.general("Could not write preparation file \(preparationFile.filepath)")
        }

        console.info("Preparation created: \(preparationFile.filepath)")
        return preparationFile
    }

    private func generatePreparationsListFile() throws {
        let preparationListFilePath = "\(preparationsFolder)/\(preparationListFile)"

        do {
            let preparations = try PreparationManager().loadPreparations(console: console)
            let lines = preparationListTemplate(preparations: preparations)
            try lines.write(toFile: preparationListFilePath, atomically: true, encoding: .utf8)
        } catch {
            throw ToolboxError.general("Could not write preparation list file \(preparationListFilePath)")
        }

        console.info("Preparation list file generated: \(preparationListFilePath)")
    }

    private func runXcodeCommand() throws {
        if console.confirm("Regenerate Xcode project?") {
            console.print("Regenerating Xcode project...")
            do {
                try Xcode(console: console).run(arguments: [])
            } catch {
                throw ToolboxError.general("Could not regenerate Xcode project")
            }
        }
    }

    private func preparationTemplate(preparationFile: PreparationFile) -> String {
        return [
            "import Fluent\n\n",
            "struct \(preparationFile.name): Preparation {\n\n",
            "    static let preparationId = \"\(preparationFile.timestamp)\"\n\n",
            "    static func prepare(_ database: Database) throws {\n",
            "        // modify the data or squema\n",
            "    }\n\n",
            "    static func revert(_ database: Database) throws {\n",
            "        // revert changes from prepare if possible\n",
            "    }\n\n",
            "}\n"
        ].joined()
    }

    private func preparationListTemplate(preparations: [PreparationFile]) -> String {
        var lines = [
            "/*\n",
            "   File auto generated by Vapor toolbox on \(Date())\n",
            "   Do not update manually.\n",
            "*/\n\n",
            "import Fluent\n\n",
            "let preparations: [Preparation.Type] = [\n"
        ]
        lines.append(preparations.map({ "    \($0.name).self" }).joined(separator: ",\n"))
        lines.append("\n]\n")
        return lines.joined()
    }

}
