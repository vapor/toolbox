import ConsoleKit
import Foundation

struct SupervisorRestart: Command {
    struct Signature: CommandSignature {
        init() { }
    }
    var help: String {
        "Restarts current project in Supervisor"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let package = try Process.swift.package.dump()
        context.console.print("Restarting \(package.name).")
        try Process.run(Shell.default.which("supervisorctl"), "restart", package.name)
        context.console.info("Project \(package.name) restarted.")
    }
}
