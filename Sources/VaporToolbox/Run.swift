import Console
import Foundation

public final class Run: Command {
    public let id = "run"

    public let help: [String] = [
        "Runs the compiled application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let folder: String

        if arguments.flag("release") {
            folder = "release"
        } else {
            folder = "debug"
        }

        do {
            _ = try console.backgroundExecute(program: "ls", arguments: [".build/\(folder)"])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("No .build/\(folder) folder found.")
        }

        do {
            let name: String

            if let n = arguments.options["name"]?.string {
                name = n
            } else if let n = try extractName() {
                name = n
            } else {
                if arguments.options["name"]?.string == nil {
                    console.info("Use --name to manually supply the package name.")
                }

                throw ToolboxError.general("Unable to determine package name.")
            }

            var passThrough = arguments.values
            for (name, value) in arguments.options {
                passThrough += "--\(name)=\(value)"
            }

            passThrough += try Config.runFlags()

            console.info("Running \(name)...")

            let path = ".build/\(folder)/\(name)"
            if FileManager.default.fileExists(atPath: "./\(path)") {
                try console.foregroundExecute(
                    program: path,
                    arguments: passThrough
                )
            } else {
                try console.foregroundExecute(
                    program: ".build/\(folder)/\(name)",
                    arguments: passThrough
                )
            }
        } catch ConsoleError.execute(_) {
            throw ToolboxError.general("Run failed.")
        }
    }

    private func extractName() throws -> String? {
        let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])

        let dumpSplit = dump.components(separatedBy: "\"name\": \"")

        guard dumpSplit.count == 2 else {
            return nil
        }

        let nameSplit = dumpSplit[1].components(separatedBy: "\"")
        return nameSplit.first
    }
}
