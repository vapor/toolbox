import Console

public final class Xcode: Command {
    public let id = "xcode"

    public let help: [String] = [
        "Generates an Xcode project for development.",
        "Additionally links commonly used libraries."
    ]

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let fetch = Fetch(console: console)
        try fetch.run(arguments: [])

        let tmpFile = "/var/tmp/vaporXcodeOutput.log"

        let xcodeBar = console.loadingBar(title: "Generate Xcode Project")
        xcodeBar.start()

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

        let command = "swift package generate-xcodeproj " + buildFlags.joined(separator: " ")

        do {
            try console.execute("\(command) > \(tmpFile) 2>&1")
            xcodeBar.finish()
        } catch ConsoleError.execute(_) {
            xcodeBar.fail()
            try console.execute("tail \(tmpFile)")
            throw Error.general("Could not generate Xcode project.")
        }

        if console.confirm("Open Xcode project?") {
            do {
                console.info("Opening Xcode project...")
                try console.execute("open *.xcodeproj")
            } catch ConsoleError.execute(_) {
                throw Error.general("Could not open Xcode project.")
            }
        }
    }

}
