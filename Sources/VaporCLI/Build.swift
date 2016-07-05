import Console

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."])
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

        let tmpFile = "/var/tmp/vaporBuildOutput.log"

        var buildFlags: [String] = [
            "-Xswiftc",
            "-I/usr/local/include/mysql",
            "-Xlinker",
            "-L/usr/local/lib"
        ]

        let buildBar = console.loadingBar(title: "Build Project")
        buildBar.start()

        for (name, value) in arguments.options {
            if ["clean", "run"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        let command = "swift build " + buildFlags.joined(separator: " ")
        do {
            try console.execute("\(command) > \(tmpFile) 2>&1")
            buildBar.finish()
        } catch ConsoleError.execute(_) {
            buildBar.fail()
            console.print()
            console.info("Command:")
            console.print(command)
            console.print()
            console.info("Output:")
            try console.execute("tail \(tmpFile)")
            console.print()
            console.info("Toolchain:")
            try console.execute("which swift")
            console.print()
            console.info("Help:")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://slack.qutheory.io")

            throw Error.general("Build failed.")
        }

        if arguments.options["run"]?.bool == true {
            let run = Run(console: console)
            try run.run(arguments: arguments)
        }
    }

}
