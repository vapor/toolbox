import Console

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."]),
        Option(name: "mysql", help: ["Links MySQL libraries."]),
        Option(name: "debug", help: ["Builds with debug symbols."])
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

        let fetch = Fetch(console: console)
        try fetch.run(arguments: [])

        var buildFlags: [String] = []

        if arguments.flag("mysql") {
            buildFlags += [
                "-Xswiftc",
                "-I/usr/local/include/mysql",
                "-Xlinker",
                "-L/usr/local/lib"
            ]
        }

        if arguments.flag("debug") {
            buildFlags += [
                "-Xswiftc",
                "-g"
            ]
        }
        
        let buildBar = console.loadingBar(title: "Building Project")
        buildBar.start()

        for (name, value) in arguments.options {
            if ["clean", "run", "mysql", "debug"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += ["--configuration", "release"]
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        let command =  ["build"] + buildFlags

        do {
            _ = try console.backgroundExecute(program: "swift", arguments: command)
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(let code, let error, _) {
            buildBar.fail()
            console.print()
            console.info("Command:")
            console.print(command.joined(separator: " "))
            console.print()
            console.info("Error (\(code)):")
            console.print(error.string)

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
            let args = arguments.filter { !["--clean", "--run"].contains($0) }
            let run = Run(console: console)
            try run.run(arguments: args)
        }
    }

}
