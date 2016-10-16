import Foundation
import Console

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
        let preparationsFolder = "./Sources/App/Preparations"

        do {
            _ = try console.backgroundExecute(program: "ls", arguments: ["./Sources/App/main.swift"])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("Invalid Vapor template: could not find Sources/App/main.swift file")
        }

        do {
            _ = try console.backgroundExecute(program: "ls", arguments: [preparationsFolder])
        } catch ConsoleError.backgroundExecute(_) {
            console.warning("No preparations folder found (\(preparationsFolder)). Creating now...")
        }

        do {
            _ = try console.backgroundExecute(program: "mkdir", arguments: ["-p", preparationsFolder])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("Failed to create preparations folder (\(preparationsFolder)).")
        }

        if arguments.count < 2 {
            throw ToolboxError.general("Missing preparation name. Usage: vapor prepare add MyFirstPreparation")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let dateStr = formatter.string(from: Date())

        let preparationName = "Preparation\(arguments[1])"
        let fileName = "\(preparationsFolder)/\(dateStr)_\(preparationName).swift"

        let template = preparationTemplate(preparationName: preparationName).joined()

        do {
            try template.write(toFile: fileName, atomically: true, encoding: .utf8)
        } catch {
            throw ToolboxError.general("Could not write preparation file \(fileName)")
        }

        console.info("Preparation created: \(fileName)")
    }

    private func preparationTemplate(preparationName: String) -> [String] {
        return [
            "import Fluent\n\n",
            "struct \(preparationName): Preparation {\n\n",
            "    static func prepare(_ database: Database) throws {\n",
            "        let sql = \"select 1\"\n",
            "        _ = try database.driver.raw(sql, [])\n",
            "    }\n\n",
            "    static func revert(_ database: Database) throws {\n",
            "        let sql = \"select 1\"\n",
            "        _ = try database.driver.raw(sql, [])\n",
            "    }\n\n",
            "}\n"
        ]
    }

}
