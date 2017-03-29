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
        let fetch = Fetch(console: console)
        try fetch.run(arguments: [])

        let verbose = arguments.verbose
        let xcodeBar = console.loadingBar(title: "Generating Xcode Project", animated: !verbose)
        xcodeBar.start()

        let buildFlags = try loadBuildFlags(arguments)
        let argsArray = ["package"] + buildFlags + ["--enable-prefetching", "generate-xcodeproj"]

        do {
            _ = try console.execute(verbose: verbose, program: "swift", arguments: argsArray)
            xcodeBar.finish()
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            xcodeBar.fail()
            console.print(message)
            throw ToolboxError.general("Could not generate Xcode project: \(message)")
        }

        // TODO: Get Executable here
        console.info("Select the `Run` scheme to run.")
        try openXcode()
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
        buildFlags += arguments
            .removeFlags(["clean", "run", "debug", "verbose", "fetch", "release"])
            .options
            .map { name, value in "--\(name)=\(value)" }

        return buildFlags
    }

    private func openXcode() throws {
        guard console.confirm("Open Xcode project?") else { return }
        console.print("Opening Xcode project...")
        _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"])
    }
}
