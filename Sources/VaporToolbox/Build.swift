import Console
import Foundation

extension Array where Element == String {
    var verbose: Bool {
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
        Option(name: "verbose", help: ["Print build logs instead of loading bar."])
    ]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let verbose = arguments.verbose

        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        if arguments.options["fetch"]?.bool != false {
            let fetch = Fetch(console: console)
            try fetch.run(arguments: arguments.filter({!$0.hasPrefix("--clean")}))
        }

        var buildFlags: [String] = []

        if arguments.flag("debug") {
            buildFlags += [
                "-Xswiftc",
                "-g"
            ]
        }

        buildFlags += try Config.buildFlags()

        let buildBar = console.loadingBar(title: "Building Project", animated: !verbose)
        buildBar.start()

        for (name, value) in arguments.options {
            if ["clean", "run", "debug", "verbose", "fetch"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += ["--configuration", "release"]
            } else {
                buildFlags += "--\(name)=\(value)"
            }
        }

        let command =  ["build", "--enable-prefetching"] + buildFlags
        do {
            try console.execute(verbose: verbose, program: "swift", arguments: command)
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(let code, let error, let output) {
            buildBar.fail()
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

        if arguments.options["run"]?.bool == true {
            let args = arguments.filter { !["--clean", "--run", "--modulemap=false"].contains($0) }
            let run = Run(console: console)
            try run.run(arguments: args)
        }
    }

}
