import Console
import Foundation

extension Array where Element == String {
    var isVerbose: Bool {
        return flag("verbose")
    }
}

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."]),
        Option(name: "fetch", help: ["Fetches the project before building, default true."]),
        Option(name: "debug", help: ["Builds with debug symbols."]),
        Option(name: "verbose", help: ["Print build logs instead of loading bar."]),
        Option(name: "release", help: ["Builds release configuration"])
    ]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        try clean(arguments)
        try fetch(arguments)
        try build(arguments)
        try run(arguments)
    }

    private func clean(_ arguments: [String]) throws {
        guard arguments.flag("clean") else { return }
        let arguments = arguments.removeFlags(["clean"])
        let clean = Clean(console: console)
        try clean.run(arguments: arguments)
    }

    private func fetch(_ arguments: [String]) throws {
        // unless explicitly false, treat as true
        let shouldFetch = arguments.option("fetch")?.bool ?? true
        guard shouldFetch else { return }

        let arguments = arguments.removeFlags(["clean", "fetch"])
        let fetch = Fetch(console: console)
        try fetch.run(arguments: arguments)
    }

    private func build(_ arguments: [String]) throws {
        let buildFlags = try loadBuildFlags(arguments)

        let isVerbose = arguments.isVerbose
        let buildBar = console.loadingBar(title: "Building Project", animated: !isVerbose)
        buildBar.start()

        let command =  ["build", "--enable-prefetching"] + buildFlags
        do {
            try console.execute(verbose: isVerbose, program: "swift", arguments: command)
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(let code, let error, let output) {
            buildBar.fail()
            try backgroundError(command: command, code: code, error: error, output: output)
        }
    }

    private func run(_ arguments: [String]) throws {
        guard arguments.flag("run") else { return }
        let args = arguments.removeFlags(["clean", "run", "fetch", "verbose"])

        let run = Run(console: console)
        try run.run(arguments: args)
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

    private func backgroundError(command: [String], code: Int, error: String, output: String) throws {
        console.print()
        console.info("Command:")
        console.print(command.joined(separator: " "))
        console.print()

        console.info("Error (\(code)):")
        console.print(error)
        console.print()

        console.info("Output:")
        console.print(output)
        console.print()

        console.info("Toolchain:")
        let toolchain = try console.backgroundExecute(program: "which", arguments: ["swift"]).trim()
        console.print(toolchain)
        console.print()

        console.info("Help:")
        console.print("Join our Slack where hundreds of contributors")
        console.print("are waiting to help: http://vapor.team")
        console.print()

        throw ToolboxError.general("Build failed.")
    }
}
