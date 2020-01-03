import ConsoleKit
import Foundation

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {}

    let help = "Builds Vapor app for CLI usage."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("Building project..")
        let result = try Process.run("swift", args: ["build"] + ctx.input.arguments)
        guard result == 0 else { throw "Failed to build." }
        ctx.console.output("Project built.")
    }
}
