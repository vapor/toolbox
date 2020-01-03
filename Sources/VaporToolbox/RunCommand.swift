import ConsoleKit
import Foundation

// Generates an Xcode project
struct RunCommand: AnyCommand {

    struct Signature: CommandSignature {}

    let help = "Runs Vapor app from CLI."

    /// See `Command`.
    func run(using ctx: inout CommandContext) throws {
        let ctx = ctx

        // execute
        let result = try Process.run("swift", args: ["run", "Run"] + ctx.input.arguments)
        guard result == 0 else { throw "Run failed." }
    }
}
