import ConsoleKit
import Foundation

// Generates an Xcode project
struct Run: AnyCommand {
    let help = "Runs an app from the console.\nEquivalent to `swift run App`.\nThe --enable-test-discovery flag is automatically set if needed."

    func run(using context: inout CommandContext) throws {
        context.console.warning("This command is deprecated. Use `swift run App` instead.")

        var flags = [String]()
        if isEnableTestDiscoveryFlagNeeded() {
            flags.append("--enable-test-discovery")
        }
        
        var extraArguments: [String] = []
        if let confirmOverride = context.console.confirmOverride {
            extraArguments.append(confirmOverride ? "--yes" : "--no")
        }

        let appName: String

        let filename = "Package.swift"
        let urlString = FileManager.default.currentDirectoryPath.trailingSlash.appendingPathComponents(filename)
        let manifestContents: String
        
        guard let url = URL(string: "file://\(urlString)") else {
            throw "Invalid URL: \(urlString)"   
        }

        context.console.info("Reading file at \(urlString)")
        
        do {
            manifestContents = try String(contentsOf: url, encoding: .utf8)
        } catch {
            context.console.error("Failed to read manifest - are you in the correct directory?")
            context.console.error("\(error)")
            return
        }

        if manifestContents.contains(".executableTarget(name: \"Run\"") {
            appName = "Run"
        } else {
            appName = "App"
        }

        context.console.info("Running \(appName)...")

        try exec(Process.shell.which("swift"), ["run"] + flags + [appName] + context.input.arguments + extraArguments)
    }

    func outputHelp(using context: inout CommandContext) {
        guard context.input.arguments.count > 1 else {
            context.console.output("\(self.help)")
            return
        }
        
        do {
            context.input.arguments.append("--help")
            try self.run(using: &context)
        } catch {
            context.console.output("error: ".consoleText(.error) + "\(error)".consoleText())
        }
    }
}
