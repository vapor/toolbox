import ConsoleKit
import Foundation

// Generates an Xcode project
struct Run: AnyCommand {
    struct Signature: CommandSignature {}

    let help = "Runs an app from the console."

    /// See `Command`.
    func run(using context: inout CommandContext) throws {
        let context = context
        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.executableURL = try URL(fileURLWithPath: Shell.default.which("swift"))
        process.arguments = ["run", "Run"] + context.input.arguments
        Process.running = process
        try process.run()
        process.waitUntilExit()
        Process.running = nil
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
