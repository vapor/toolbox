import Console

public final class Xcode: Command {
    public let id = "xcode"

    public let help: [String] = [
        "Generates an Xcode project for development.",
        "Additionally links commonly used libraries."
    ]

    public let signature: [Argument] = [
        Option(name: "mysql", help: ["Links MySQL libraries."])
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let fetch = Fetch(console: console)
        try fetch.run(arguments: [])

        let tmpFile = "/var/tmp/vaporXcodeOutput.log"

        let xcodeBar = console.loadingBar(title: "Generating Xcode Project")
        xcodeBar.start()

        var buildFlags: [String] = []
        
        if arguments.flag("mysql") {
            buildFlags += [
                "-Xswiftc",
                "-I/usr/local/include/mysql",
                "-Xlinker",
                "-L/usr/local/lib"
            ]
        }


        for (name, value) in arguments.options {
            if ["mysql"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        var commandArray = ["swift", "package", "generate-xcodeproj"]
        commandArray += buildFlags
        
        let command = commandArray.joined(separator: " ")

        do {
            _ = try console.subexecute("\(command) > \(tmpFile) 2>&1")
            xcodeBar.finish()
        } catch ConsoleError.subexecute(_, let message) {
            xcodeBar.fail()
            print(message)
            throw ToolboxError.general("Could not generate Xcode project: \(message)")
        }

        console.info("Select the `App` scheme to run.")
        do {
            let version = try console.subexecute("cat .swift-version").trim()
            console.warning("Make sure Xcode > Toolchains > \(version) is selected.")
        } catch ConsoleError.subexecute(_, let message) {
            console.error("Could not determine Swift version: \(message)")
        }

        if console.confirm("Open Xcode project?") {
            do {
                console.print("Opening Xcode project...")
                _ = try console.subexecute("open *.xcodeproj")
            } catch ConsoleError.subexecute(_) {
                throw ToolboxError.general("Could not open Xcode project.")
            }
        }
    }

}
