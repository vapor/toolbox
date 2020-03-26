import ConsoleKit
import Foundation

// Generates an Xcode project
struct Run: AnyCommand {
    let help = "Runs an app from the console."

    func run(using context: inout CommandContext) throws {
        try exec("/usr/bin/swift", ["run", "--enable-test-discovery", "Run"] + context.input.arguments)
    }

    func outputHelp(using context: inout CommandContext) {
        do {
            context.input.arguments.append("--help")
            try self.run(using: &context)
        } catch {
            context.console.output("error: ".consoleText(.error) + "\(error)".consoleText())
        }
    }
}
