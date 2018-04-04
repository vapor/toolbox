import Console

public final class HerokuInit: Command {
    public let id = "init"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Prepares the application for Heroku integration."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {

        func gitIsClean(log: Bool = true) throws {
            do {
                let status = try console.backgroundExecute(program: "git", arguments: ["status", "--porcelain"])
                if status.trim() != "" {
                    if log {
                        console.info("All current changes must be committed before running a Heroku init.")
                    }
                    throw ToolboxError.general("Found uncommitted changes.")
                }
            } catch ConsoleError.backgroundExecute {
                throw ToolboxError.general("No .git repository found.")
            }
        }

        try gitIsClean()

        do {
            let branches = try console.backgroundExecute(program: "git", arguments: ["branch"])
            guard branches.contains("* master") else {
                throw ToolboxError.general(
                    "Please checkout master branch before initializing heroku. 'git checkout master'"
                )
            }
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            throw ToolboxError.general("Unable to locate current git branch: \(message)")
        }

        do {
            _ = try console.backgroundExecute(program: "which", arguments: ["heroku"])
        } catch ConsoleError.backgroundExecute {
            console.info("Visit https://toolbelt.heroku.com")
            throw ToolboxError.general("Heroku Toolbelt must be installed.")
        }

        do {
            _ = try console.backgroundExecute(program: "git", arguments: ["remote", "show", "heroku"])
            throw ToolboxError.general("Git already has a heroku remote.")
        } catch ConsoleError.backgroundExecute {
            //continue
        }

        let name: String
        if console.confirm("Would you like to provide a custom Heroku app name?") {
            name = console.ask("Custom app name:")
        } else {
            name = ""
        }
        
        let region: String
        if console.confirm("Would you like to deploy to a region other than the US?") {
            region = console.ask("Region code (us/eu):")
        } else {
            region = "us"
        }

        let url: String
        do {
            url = try console.backgroundExecute(program: "heroku", arguments: ["create", name, "--region", region])
            console.info(url)
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            throw ToolboxError.general("Unable to create Heroku app: \(message.trim())")
        }

        let buildpack: String
        if console.confirm("Would you like to provide a custom Heroku buildpack?") {
            buildpack = console.ask("Custom buildpack:")
        } else {
            buildpack = "https://github.com/vapor-community/heroku-buildpack"
        }


        console.info("Setting buildpack...")

        do {
            _ = try console.backgroundExecute(program: "heroku", arguments: ["buildpacks:set", "\(buildpack)"])
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            throw ToolboxError.general("Unable to set buildpack \(buildpack): \(message)")
        }


        let appName: String
        if console.confirm("Are you using a custom Executable name?") {
            appName = console.ask("Executable Name:")
        } else {
            appName = "Run"
        }

        console.info("Setting procfile...")
        do {
            let procContents: String
            let majorVersion = try projectInfo.vaporMajorVersion()
            if majorVersion >= 3 {
                procContents = "web: \(appName) --env production --hostname 0.0.0.0 --port \\$PORT"
            } else {
                procContents = "web: \(appName) --env=production --port=\\$PORT"
            }
            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "echo \"\(procContents)\" >> ./Procfile"])
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            throw ToolboxError.general("Unable to make Procfile: \(message)")
        }

        console.info("Committing procfile...")
        do {
            try gitIsClean(log: false) // should throw
        } catch {
          // if not clean, commit.
          _ = try console.backgroundExecute(program: "git", arguments: ["add", "."])
          _ = try console.backgroundExecute(program: "git", arguments: ["commit", "-m",  "'adding procfile'"])
        }

        if console.confirm("Would you like to push to Heroku now?") {
            console.warning("This may take a while...")

            let buildBar = console.loadingBar(title: "Building on Heroku ... ~5-10 minutes", animated: !arguments.isVerbose)
            buildBar.start()
            do {
                _ = try console.execute(verbose: arguments.isVerbose, program: "git", arguments: ["push", "heroku", "master"])
              buildBar.finish()
            } catch ConsoleError.backgroundExecute(_, let message, _) {
              buildBar.fail()
              throw ToolboxError.general("Heroku push failed \(message)")
            } catch {
                // prevents foreground executions from logging 'Done' instead of 'Failed'
                buildBar.fail()
                throw error
            }

            let dynoBar = console.loadingBar(title: "Spinning up dynos", animated: !arguments.isVerbose)
            dynoBar.start()
            do {
                _ = try console.execute(verbose: arguments.isVerbose, program: "heroku", arguments: ["ps:scale", "web=1"])
                dynoBar.finish()
            } catch ConsoleError.backgroundExecute(_, let message, _) {
                dynoBar.fail()
                throw ToolboxError.general("Unable to spin up dynos: \(message)")
            } catch {
                // prevents foreground executions from logging 'Done' instead of 'Failed'
                dynoBar.fail()
                throw error
            }

            console.print("Visit https://dashboard.heroku.com/apps/")
            console.success("App is live on Heroku, visit \n\(url)")
        } else {
            console.info("You may push to Heroku later using:")
            console.print("git push heroku master")
            console.warning("Don't forget to scale up dynos:")
            console.print("heroku ps:scale web=1")
        }
    }

}
