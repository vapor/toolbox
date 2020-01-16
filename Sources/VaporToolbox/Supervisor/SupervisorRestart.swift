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
        let task = try Process.new(Shell.default.which("supervisorctl"), "restart", package.name)
        task.onOutput {
            context.console.print($0)
        }
        try task.runUntilExit()
        context.console.info("Supervisor restarted \(package.name)")
    }
}
