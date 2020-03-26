import ConsoleKit
import Foundation

// Generates an Xcode project
struct Build: AnyCommand {
    let help = "Builds an app in the console."

    func run(using context: inout CommandContext) throws {
        context.console.output("Building project...")
        try exec(Process.shell.which("swift"), ["build", "--enable-test-discovery"] + context.input.arguments)
        context.console.info("Project built.")
    }
}
