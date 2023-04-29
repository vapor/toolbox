import ConsoleKit
import Foundation

// Generates an Xcode project
struct Run: AnyCommand {
    let help = "Runs an app from the console.\nEquivalent to `swift run App`.\nThe --enable-test-discovery flag is automatically set if needed."

    func run(using context: inout CommandContext) throws {
        ctx.console.warning("This command is deprecated. Use `swift run App` instead.")

        var flags = [String]()
        if isEnableTestDiscoveryFlagNeeded() {
            flags.append("--enable-test-discovery")
        }
        
        var extraArguments: [String] = []
        if let confirmOverride = context.console.confirmOverride {
            extraArguments.append(confirmOverride ? "--yes" : "--no")
        }
        try exec(Process.shell.which("swift"), ["run"] + flags + ["Run"] + context.input.arguments + extraArguments)
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
