import ConsoleKit
import Foundation

// Generates an Xcode project
struct Build: Command {
    struct Signature: CommandSignature {}

    let help = "Builds an app in the console."

    /// See `Command`.
    func run(using context: CommandContext, signature: Signature) throws {
        context.console.output("Building project...")
        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.executableURL = try URL(fileURLWithPath: Shell.default.which("swift"))
        process.arguments = ["build"]
        Process.running = process
        try process.run()
        process.waitUntilExit()
        Process.running = nil
        context.console.info("Project built.")
    }
}
