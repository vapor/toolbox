import ConsoleKit
import Foundation

struct SupervisorUpdate: Command {
    struct Signature: CommandSignature {
        init() { }
    }
    var help: String {
        "Updates Supervisor entry for current project"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        context.console.warning("This command is deprecated. Use `supervisorctl update <AppName>` instead.")

        let package = try Process.swift.package.dump()
        try Process.run(Process.shell.which("supervisorctl"), "update", package.name)
        context.console.info("Supervisor entry for \(package.name) updated.")
    }
}
