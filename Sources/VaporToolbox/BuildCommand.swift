import ConsoleKit
import Foundation

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {}

    let help = "Builds an app in the console."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("Building project..")
        let task = try Process.new("swift", ["build"] + ctx.input.arguments)
        task.onOutput { output in
            ctx.console.output(output.consoleText())
        }
        try task.runUntilExit()
        ctx.console.output("Project built.")
    }
}
