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
        do {
            let executable = try executablePath(arguments)

            let configuredRunFlags = try Config.runFlags()
            let passThrough = arguments + configuredRunFlags

            let packageName = try extractPackageName(with: console)
            console.info("Running \(packageName) ...")

            try console.foregroundExecute(
                program: executable,
                arguments: passThrough
            )
        } catch ConsoleError.execute(_) {
            throw ToolboxError.general("Run failed.")
        }
    }

    private func buildFolder(_ arguments: [String]) throws -> String {
        let folder: String
        if arguments.flag("release") {
            folder = ".build/release"
        } else {
            folder = ".build/debug"
        }

        do {
            _ = try console.backgroundExecute(program: "ls", arguments: [folder])
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("No \(folder) folder found.")
        }

        return folder
    }

    private func executablePath(_ arguments: [String]) throws -> String {
        let folder = try buildFolder(arguments)
        let exec = try arguments.options["exec"] ?? getExecutableToRun()
        let executablePath = "\(folder)/\(exec)"
        try verify(executablePath: executablePath)
        return executablePath
    }

    private func verify(executablePath: String) throws {
        let pathExists = try console.backgroundExecute(program: "ls", arguments: [executablePath])
        guard pathExists.trim() == executablePath else {
            throw ToolboxError.general("Could not find executable at \(executablePath)")
        }
    }

    private func getExecutableToRun() throws -> String {
        let executables = try findExecutables(with: console)
        guard !executables.isEmpty else {
            throw ToolboxError.general("No executables found")
        }

        // If there's only 1 executable, we'll use that
        if executables.count == 1 {
            return executables[0]
        }

        let title = "Which executable would you like to run?"
        guard let executable = console.askList(withTitle: title, from: executables) else {
            console.print("Please enter a valid number associated with your executable")
            console.print("Use --exec=desiredExecutable to skip this step")
            throw ToolboxError.general("No executable selected")
        }
        console.info("Thanks! Skip this question in the future by using '--exec=\(executable)'")
        return executable
    }
}

internal func extractPackageName(with console: ConsoleProtocol) throws -> String {
    let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
    guard let json = try? JSON(bytes: dump.bytes), let name = json["name"]?.string else {
        throw ToolboxError.general("Unable to determine package name.")
    }
    return name
}

internal func findExecutables(with console: ConsoleProtocol) throws -> [String] {
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
            return try extractPackageName(with: console)
        }
        return name
    }
}


extension ConsoleProtocol {
    public func askList(withTitle title: String, from list: [String]) -> String? {
        info(title)
        list.enumerated().forEach { idx, item in
            // offset 0 to start at 1
            let offset = idx + 1
            info("\(offset): ", newLine: false)
            print(item)
        }
        output("> ", style: .plain, newLine: false)
        let raw = input()
        guard let idx = Int(raw) else {
            // .count is implicitly offset, no need to adjust
            warning("Invalid selection '\(raw)', expected: 1...\(list.count)")
            return nil
        }
        // undo previous offset back to 0 indexing
        let offset = idx - 1
        guard offset < list.count else { return nil }
        return list[offset]
    }
}
