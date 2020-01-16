import ConsoleKit
import Foundation

// Generates an Xcode project
struct Xcode: Command {
    struct Signature: CommandSignature { }

    let help = "Opens an app in Xcode."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.info("Opening project in Xcode.")
        do {
            try Shell.default.run("open", "Package.swift")
        } catch {
            ctx.console.output("note: ".consoleText(.warning) + "Call this command from the project's root folder.")
            throw error
        }
    }
}
