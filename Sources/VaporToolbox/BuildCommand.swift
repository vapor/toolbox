import ConsoleKit
import Foundation

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {}

    let help = "Builds an app in the console."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("Building project..")
        try Process.run("swift", args: ["build"] + ctx.input.arguments)
        ctx.console.output("Project built.")
    }
}
