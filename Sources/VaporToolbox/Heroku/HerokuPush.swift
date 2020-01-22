import ConsoleKit
import Foundation

struct HerokuPush: Command {
    struct Signature: CommandSignature { }

    let signature = Signature()
    let help = "Deploys app to Heroku."

    func run(using context: CommandContext, signature: Signature) throws {
        // Get Swift package name
        let name = try Process.swift.package.dump().name
        context.console.list(key: "Package", value: name)

        // Check if git is clean.
        if try !Process.git.isClean() {
            context.console.warning("Git has uncommitted changes.")
        }

        // Check current git branch.
        let branch = try Process.git.currentBranch()
        context.console.list(key: "Git branch", value: branch)
        if branch != "master" {
            context.console.warning("You are not currently on 'master' branch.")
        }

        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.executableURL = try URL(fileURLWithPath: Process.shell.which("git"))
        process.arguments = ["push", "heroku", branch]
        Process.running = process
        try process.run()
        process.waitUntilExit()
        Process.running = nil
    }
}
