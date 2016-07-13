import Console

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."]),
        Option(name: "mysql", help: ["Links MySQL libraries."])
    ]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: Console

    public init(console: Console) {
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

        let buildBar = console.loadingBar(title: "Building Project")
        buildBar.start()

        for (name, value) in arguments.options {
            if ["clean", "run", "mysql"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        var commandArray = ["swift", "build"]
        commandArray += buildFlags

        commandArray += "1>&2"

        let command = commandArray.joined(separator: " ")
        do {
            _ = try console.subexecute(command)
            buildBar.finish()
        } catch ConsoleError.subexecute(let code, let error) {
            buildBar.fail()
            console.print()
            console.info("Command:")
            console.print(command)
            console.print()
            console.info("Error (\(code)):")
            console.print(error)

            console.info("Toolchain:")
            let toolchain = try console.subexecute("which swift").trim()
            console.print(toolchain)
            console.print()
            console.info("Help:")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://slack.qutheory.io")
            console.print()

            throw Error.general("Build failed.")
        }

        if arguments.options["run"]?.bool == true {
            let args = arguments.filter { !["--clean", "--run"].contains($0) }
            let run = Run(console: console)
            try run.run(arguments: args)
        }
    }

}
