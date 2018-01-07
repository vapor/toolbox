import Console
import Foundation

public final class Xcode: Command {
    public let id = "xcode"

    public let help: [String] = [
        "Generates an Xcode project for development.",
        "Additionally links commonly used libraries."
    ]

    public let signature: [Argument] = []

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let isVerbose = arguments.isVerbose
        let xcodeBar = console.loadingBar(title: "Generating Xcode Project", animated: !isVerbose)
        xcodeBar.start()

        let buildFlags = try loadBuildFlags(arguments)
        let argsArray = ["package"] + buildFlags + ["--enable-prefetching", "generate-xcodeproj"]

        do {
            _ = try console.execute(verbose: isVerbose, program: "swift", arguments: argsArray)
            xcodeBar.finish()
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            xcodeBar.fail()
            console.print(message)
            throw ToolboxError.general("Could not generate Xcode project: \(message)")
        } catch {
            // prevents foreground executions from logging 'Done' instead of 'Failed'
            xcodeBar.fail()
            throw error
        }

        try logExecutableInfo()
        try openXcode(arguments)
    }

    private func fetch(_ arguments: [String]) throws {
        let needsFetch = !projectInfo.buildFolderExists()
        let shouldFetch = arguments.option("fetch")?.bool ?? needsFetch
        guard shouldFetch else { return }

        let arguments = arguments.removeFlags(["clean", "fetch", "y"])
        let fetch = Fetch(console: console)
        try fetch.run(arguments: arguments)
    }

    private func logExecutableInfo() throws {
        // If it's not a Vapor project, don't log warnings
        guard projectInfo.isVaporProject() else { return }

        let executables = try projectInfo.availableExecutables()
        if executables.isEmpty {
            console.info("No executable found, make sure to create")
            console.info("a target that includes a 'main.swift' file")
            console.info("then regenerate your project")
        } else if executables.count == 1 {
            let executable = executables[0]
            console.info("Select the `\(executable)` scheme to run.")
        } else {
            console.info("Select one of your executables to run.")
            executables.forEach { exec in
                console.print("- \(exec)")
            }
        }
    }

    private func loadBuildFlags(_ arguments: [String]) throws -> [String] {
        var buildFlags = try Config.buildFlags()

        if arguments.flag("debug") {
            // Appending these flags aids in debugging
            // symbols on linux
            buildFlags += ["-Xswiftc", "-g"]
        }

        if arguments.flag("release") {
            buildFlags += ["--configuration", "release"]
        }

        // Setup passthrough
        let clean = arguments
            .removeFlags(["clean", "run", "debug", "verbose", "fetch", "release", "y", "n"])
        buildFlags += clean
            .options
            .map { name, value in "--\(name)=\(value)" }
        buildFlags += clean.values

        return buildFlags
    }

    private func openXcode(_ arguments: [String]) throws {
        guard console.confirm("Open Xcode project?") else { return }
        console.print("Opening Xcode project...")
        _ = try console.execute(verbose: arguments.isVerbose, program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"])
    }
}
