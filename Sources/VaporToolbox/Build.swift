import Console
import Foundation

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."]),
        Option(name: "fetch", help: ["Fetches the project before building, default true."]),
        Option(name: "mysql", help: ["Links MySQL libraries."]),
        Option(name: "debug", help: ["Builds with debug symbols."]),
        Option(name: "verbose", help: ["Print build logs instead of loading bar."]),
        Option(name: "modulemap", help: ["Add CLibreSSL module map for faster builds, default true."]),
    ]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        if arguments.options["fetch"]?.bool != false {
            let fetch = Fetch(console: console)
            try fetch.run(arguments: [])
        }

        #if !swift(>=3.1)
            if arguments.options["modulemap"]?.bool != false {
                do {
                    let mod = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "ls Packages | grep CLibreSSL"]).trim()
                    _ = try console.backgroundExecute(program: "ls", arguments: ["Packages/\(mod)/Sources/CLibreSSL/include/module.modulemap"])
                } catch {
                    // not found
                    do {
                        _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "printf \"module CLibreSSL {\\n    header \\\"CLibreSSL.h\\\"\\n    link \\\"CLibreSSL\\\"\\n}\" > Packages/CLibreSSL-1.0.0/Sources/CLibreSSL/include/module.modulemap"])
                    } catch {
                        console.warning("Could not add CLibreSSL Module Map: \(error)")
                    }
                }
            }
        #endif

        var buildFlags: [String] = []

        if arguments.flag("debug") {
            buildFlags += [
                "-Xswiftc",
                "-g"
            ]
        }

        buildFlags += try Config.buildFlags()

        let buildBar: LoadingBar?
        if arguments.options["verbose"]?.bool != true {
            buildBar = console.loadingBar(title: "Building Project")
            buildBar?.start()
        } else {
            buildBar = nil
        }

        for (name, value) in arguments.options {
            if ["clean", "run", "mysql", "debug", "verbose", "fetch", "modulemap"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += ["--configuration", "release"]
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        #if swift(>=3.1)
            let command =  ["build", "--enable-prefetching"] + buildFlags
        #else
            let command =  ["build"] + buildFlags
        #endif
        do {
            if arguments.options["verbose"]?.bool == true {
                console.print("Building Project...")
                try console.foregroundExecute(program: "swift", arguments: command)
            } else {
                _ = try console.backgroundExecute(program: "swift", arguments: command)
                buildBar?.finish()
            }
        } catch ConsoleError.backgroundExecute(let code, let error, let output) {
            buildBar?.fail()
            console.print()
            console.info("Command:")
            console.print(command.joined(separator: " "))
            console.print()

            console.info("Error (\(code)):")
            console.print(error.string)
            console.print()

            console.info("Output:")
            console.print(output.string)
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
