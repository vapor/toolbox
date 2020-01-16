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
        let package = try Process.swift.package.dump()
        try Process.run(Shell.default.which("supervisorctl"), "update", package.name)
        context.console.info("Supervisor entry for \(package.name) updated.")
    }
}
