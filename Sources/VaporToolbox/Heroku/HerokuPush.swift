import ConsoleKit
import Foundation

struct HerokuPush: Command {
    struct Signature: CommandSignature { }

    let signature = Signature()
    let help = "Deploys app to Heroku."

    func run(using context: CommandContext, signature: Signature) throws {
        context.console.warning("This command is deprecated. Use `git push heroku <branch>` instead.")

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

        try exec(Process.shell.which("git"), "push", "heroku", branch)
    }
}
