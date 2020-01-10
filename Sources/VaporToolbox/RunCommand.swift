import ConsoleKit
import Foundation

// Generates an Xcode project
struct RunCommand: AnyCommand {
    struct Signature: CommandSignature {}

    let help = "Runs an app from the console."

    /// See `Command`.
    func run(using ctx: inout CommandContext) throws {
        try Process.run("swift", args: ["run", "Run"] + ctx.input.arguments)
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
