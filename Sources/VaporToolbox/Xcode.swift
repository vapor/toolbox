import Console
import Foundation

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

        let xcodeBar = console.loadingBar(title: "Generating Xcode Project")
        xcodeBar.start()

        var buildFlags: [String] = []

        buildFlags += try Config.buildFlags()

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

        #if !swift(>=3.1)
            do {
                _ = try console.backgroundExecute(
                    program: "/bin/sh",
                    arguments: ["-c", "rm -rf Packages/CLibreSSL-1.*/Sources/CLibreSSL/include/module.modulemap"]
                )
            } catch {
                console.warning("Could not remove module map.")
            }
        #endif

        #if swift(>=3.1)
            let argsArray = ["package"] + buildFlags + ["--enable-prefetching", "generate-xcodeproj"]
        #else
            let argsArray = ["package", "generate-xcodeproj"] + buildFlags
        #endif

        do {
            _ = try console.backgroundExecute(program: "swift", arguments: argsArray)
            xcodeBar.finish()
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            xcodeBar.fail()
            console.print(message.string)
            throw ToolboxError.general("Could not generate Xcode project: \(message.string)")
        }

        console.info("Select the `App` scheme to run.")

        if console.confirm("Open Xcode project?") {
            do {
                console.print("Opening Xcode project...")
                _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "open *.xcodeproj"])
            } catch ConsoleError.backgroundExecute(_) {
                throw ToolboxError.general("Could not open Xcode project.")
            }
        }
    }

}
