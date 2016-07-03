import Console

public final class Build: Command {
    public static let id = "build"

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {

        let loadingBar = console.loadingBar(title: "Build")
        loadingBar.start()

        let tmpFile = "/var/tmp/vaporBuildOutput.log"

        do {
            try console.execute("swift package fetch > \(tmpFile) 2>&1")
        } catch ConsoleError.execute(_) {
            loadingBar.fail()
            try console.execute("tail \(tmpFile)")
            throw Error.general("Could not fetch dependencies.")
        }

        var buildFlags: [String] = [
            "-Xswiftc",
            "-I/usr/local/include/mysql",
            "-Xlinker",
            "-L/usr/local/lib"
        ]

        for (name, value) in arguments.options {
            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        let command = "swift build " + buildFlags.joined(separator: " ")
        do {
            try console.execute("\(command) > \(tmpFile) 2>&1")
            loadingBar.finish()
        } catch ConsoleError.execute(_) {
            loadingBar.fail()
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
            console.info("Need help getting your project to build?")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://slack.qutheory.io")

            throw Error.general("Build failed.")
        }
    }

    public let help: [String] = [
        "Compiles the application."
    ]
}
