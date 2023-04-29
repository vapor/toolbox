import ConsoleKit
import Foundation
#if os(macOS)
import AppKit
#endif

// Generates an Xcode project
struct Xcode: Command {
    struct Signature: CommandSignature { }

    let help = "Opens an app in Xcode."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.warning("This command is deprecated. Use `open Package.swift` or `code .` instead.")

        ctx.console.info("Opening project in Xcode.")
        do {
            #if os(macOS)
            NSWorkspace.shared.open(FileManager.default.currentDirectoryPath.appendingPathComponents("Package.swift").asFileURL)
            #else
            try Process.shell.run("open", "Package.swift")
            #endif
        } catch {
            ctx.console.output("note: ".consoleText(.warning) + "Call this command from the project's root folder.")
            throw error
        }
    }
}
