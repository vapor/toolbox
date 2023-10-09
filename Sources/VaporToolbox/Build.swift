import ConsoleKit
import Foundation

// Generates an Xcode project
struct Build: AnyCommand {
    let help = "Builds an app in the console."

    func run(using context: inout CommandContext) throws {
        context.console.warning("This command is deprecated. Use `swift build` instead.")

        context.console.output("Building project...")
        
        var flags = [String]()
        
        if isEnableTestDiscoveryFlagNeeded() {
            flags.append("--enable-test-discovery")
        }
        
        try exec(Process.shell.which("swift"), ["build"] + flags + context.input.arguments)
        context.console.info("Project built.")
    }
}
