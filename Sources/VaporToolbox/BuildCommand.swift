import ConsoleKit
import Foundation

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {}

    let help = "Builds Vapor app for CLI usage."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("Building project..")
        // execute
        let result = try Process.run("swift", args: ["build"] + ctx.input.arguments) { update in
            if let err = update.err {
                ctx.console.output(err, style: .error, newLine: false)
            }
            if let out = update.out {
                ctx.console.output(out, style: .plain, newLine: false)
            }
        }

        guard result == 0 else { throw "Failed to build." }
        ctx.console.output("Project built.")
    }
}
