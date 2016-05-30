
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

    static func execute(with args: [String], in directory: String) {
        executeSubCommand(with: args, in: directory)
    }
}

extension Heroku {
    struct Init: Command {
        static let id = "init"

        static var help: [String] {
            return [
                       "Configures a new heroku project"
            ]
        }

        static func execute(with args: [String], in directory: String) {
            guard args.isEmpty else { fail("heroku init takes no args") }

            if !gitHistoryIsClean() {
                print("Found Uncommitted Changes")
                print("Setting up heroku requires adding a commit to the repository")
                print("Please commit your current changes before setting up heroku")
                fail("")
            }

            let packageName = getPackageName()
            print("Setting up Heroku for \(packageName) ...")
            print()

            let herokuIsAlreadyInitialized = passes("git remote show heroku")
            if herokuIsAlreadyInitialized {
                print("Found existing heroku app")
                print()
            } else {
                print("Custom Heroku App Name? (return to let Heroku create)")
                let herokuAppName = getInput()
                do {
                    try run("heroku create \(herokuAppName)")
                } catch {
                    fail("unable to create heroku app")
                }
            }

            print("Custom Buildpack? (return to use default)")
            var buildpack = ""
            if let input = readLine(strippingNewline: true) where !buildpack.isEmpty {
                buildpack = input
            } else {
                buildpack = "https://github.com/kylef/heroku-buildpack-swift"
            }

            do {
                try run("heroku buildpacks:set \(buildpack)")
                print("Using buildpack: \(buildpack)")
                print()
            } catch Error.system(let code) where code == 256 {
                print()
            } catch {
                fail("unable to set buildpack: \(buildpack)")
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
                try run("echo \"\(procContents)\" > ./Procfile")
            } catch {
                fail("Unable to make Procfile")
            }

            print()
            print("Would you like to push to heroku now? (y/n)")
            let input = getInput().lowercased()
            if input.hasPrefix("n") {
                print("\n\n")
                print("Make sure to push your changes to heroku using:")
                print("\t'git push heroku master'")
                print("You may need to scale up dynos")
                print("\t'heroku ps:scale web=1'")
                exit(0)
            }

            print()
            print("Pushing to heroku ... this could take a while")
            print()

            system("git add .")
            system("git commit -m \"setting up heroku\"")
            system("git push heroku master")
            
            print("spinning up dynos ...")
            do {
                try run("heroku ps:scale web=1")
            } catch {
                fail("unable to spin up dynos")
            }
        }
    }
}
