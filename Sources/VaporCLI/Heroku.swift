
#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

struct Heroku: Command {
    static let id = "heroku"

    static var dependencies = ["git", "heroku"]

    static var subCommands: [Command.Type] = [
        Heroku.Init.self,
        ]

    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        try executeSubCommand(with: args, in: shell)
    }
}

extension Heroku {
    // made available in this way so we can inject a path while testing
    internal static var _packageFile: ContentProvider = Path("./Package.swift")

    struct Init: Command {
        static let id = "init"

        static var help: [String] {
            return [
                "Configures a new heroku project"
            ]
        }

        static func execute(with args: [String], in shell: PosixSubsystem) throws {
            guard args.isEmpty else {
                throw Error.failed("heroku init takes no args")
            }

            // FIXME: unhandled error:
            //        fatal: Not a git repository (or any of the parent directories): .git

            // FIXME
            if !gitHistoryIsClean() {
                let msg = ["Found Uncommitted Changes",
                           "Setting up heroku requires adding a commit to the repository",
                           "Please commit your current changes before setting up heroku",]
                throw Error.failed(msg.joined(separator: "\n"))
            }

            // FIXME
            let packageName = extractPackageName(from: Heroku._packageFile)
            print("Setting up Heroku for \(packageName) ...")
            print()

            // FIXME
            let herokuIsAlreadyInitialized = shell.passes("git remote show heroku")
            if herokuIsAlreadyInitialized {
                print("Found existing heroku app")
                print()
            } else {
                print("Custom Heroku App Name? (return to let Heroku create)")
                if let herokuAppName = shell.getInput() {
                    do {
                        try "heroku create \(herokuAppName)".run(in: shell)
                    } catch {
                        throw Error.failed("unable to create heroku app")
                    }
                } else {
                    throw Error.cancelled("Please try again and provide a valid app name")
                }
            }

            print("Custom Buildpack? (return to use default)")
            var buildpack = ""
            if let input = shell.getInput() where !buildpack.isEmpty {
                buildpack = input
            } else {
                buildpack = "https://github.com/kylef/heroku-buildpack-swift"
            }

            do {
                try "heroku buildpacks:set \(buildpack)".run(in: shell)
                print("Using buildpack: \(buildpack)")
                print()
            } catch Error.system(let code) where code == 256 {
                print()
            } catch {
                throw Error.failed("unable to set buildpack: \(buildpack)")
            }

            print("Creating Procfile ...")
            // TODO: Discuss
            // Should it be
            //    let procContents = "web: \(packageName) --port=\\$PORT"
            // It causes errors like that and forces `App` as process.
            // Forces us to use Vapor CLI
            // Maybe that's something we want
            let procContents = "web: App --port=\\$PORT"
            do {
                // Overwrites existing Procfile
                try "echo \"\(procContents)\" > ./Procfile".run(in: shell)
            } catch {
                throw Error.failed("Unable to make Procfile")
            }

            print()
            print("Would you like to push to heroku now? (y/n)")
            let input = (shell.getInput() ?? "").lowercased()
            if input.hasPrefix("n") {
                print("\n\n")
                print("Make sure to push your changes to heroku using:")
                print("\t'git push heroku master'")
                print("You may need to scale up dynos")
                print("\t'heroku ps:scale web=1'")
                return
            }

            print()
            print("Pushing to heroku ... this could take a while")
            print()

            do {
                try shell.run("git add .")
                try shell.run("git commit -m \"setting up heroku\"")
                try shell.run("git push heroku master")
            } catch {
                throw Error.failed("Unable to push to heroku")
            }

            print("spinning up dynos ...")
            do {
                try "heroku ps:scale web=1".run(in: shell)
            } catch {
                throw Error.failed("unable to spin up dynos")
            }
        }
    }
}
