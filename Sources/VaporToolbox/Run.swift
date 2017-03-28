import Console
import Foundation
import JSON

public final class Run: Command {
    public let id = "run"

    public let help: [String] = [
        "Runs the compiled application."
    ]

    public let signature: [Argument] = [
        Option(name: "exec", help: ["The executable name."])
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
            let packageName = try extractPackageName()
            let exec = try arguments.options["exec"] ?? getExecutableToRun()

            let configuredRunFlags = try Config.runFlags()
            let passThrough = arguments + configuredRunFlags

            console.info("Running \(packageName) ...")

            let path = ".build/\(folder)/\(exec)"
            guard FileManager.default.fileExists(atPath: "./\(path)") else {
                throw ToolboxError.general("Could not find executable at \(path)")
            }
            try console.foregroundExecute(
                program: path,
                arguments: passThrough
            )
        } catch ConsoleError.execute(_) {
            throw ToolboxError.general("Run failed.")
        }
    }

    private func getExecutableToRun() throws -> String {
        let executables = try findExecutables()
        guard !executables.isEmpty else {
            throw ToolboxError.general("No executables found")
        }

        // If there's only 1 executable, we'll use that
        if executables.count == 1 {
            return executables[0]
        }

        let formatted = executables.enumerated()
            .map { idx, option in "\(idx + 1): \(option)" }
            .joined(separator: "\n")

        let answer = console.ask("Which executable would you like to run?\n\(formatted)")
        // <= because count is offset by 1 in selection process!
        guard let idx = answer.int, idx > 0, idx <= executables.count else {
            console.print("Please enter a valid number associated with your executable")
            console.print("Use --exec=desiredExecutable to skip this step")
            throw ToolboxError.general("Invalid selection \(answer) expected valid index.")
        }

        let exec = executables[idx - 1]
        console.info("Thanks! Skip this question in the future by using '--exec=\(exec)'")
        return exec
    }

    private func extractPackageName() throws -> String {
        let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
        let json = try JSON(bytes: dump.bytes)
        guard let name = json["name"]?.string else {
            throw ToolboxError.general("Unable to find package name")
        }
        return name
    }

    private func findExecutables() throws -> [String] {
        let executables = try console.backgroundExecute(
            program: "find",
            arguments: ["./Sources", "-type", "f", "-name", "main.swift"]
        )
        let names = executables.components(separatedBy: "\n")
            .flatMap { path in
                return path.components(separatedBy: "/")
                    .dropLast() // drop main.swift
                    .last // get name of source folder
            }

        // For the use case where there's one package
        // and user hasn't setup lower level paths
        return try names.map { name in
            if name == "Sources" {
                return try extractPackageName()
            }
            return name
        }
    }
}
