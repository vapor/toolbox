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

        func gitIsClean() throws {
          do {
              let status = try console.backgroundExecute(program: "git", arguments: ["status", "--porcelain"])
              if status.trim() != "" {
                  console.info("All current changes must be committed before running a Heroku init.")
                  throw ToolboxError.general("Found uncommitted changes.")
              }
          } catch ConsoleError.backgroundExecute(_, _) {
              throw ToolboxError.general("No .git repository found.")
          }
        }

        try gitIsClean()

        do {
            _ = try console.backgroundExecute(program: "which", arguments: ["heroku"])
        } catch ConsoleError.backgroundExecute(_, _) {
            console.info("Visit https://toolbelt.heroku.com")
            throw ToolboxError.general("Heroku Toolbelt must be installed.")
        }

        do {
            _ = try console.backgroundExecute(program: "git", arguments: ["remote", "show", "heroku"])
            throw ToolboxError.general("Git already has a heroku remote.")
        } catch ConsoleError.backgroundExecute(_, _) {
            //continue
        }

        let name: String
        if console.confirm("Would you like to provide a custom Heroku app name?") {
            name = console.ask("Custom app name:").string ?? ""
        } else {
            name = ""
        }

        do {
            let message = try console.backgroundExecute(program: "heroku", arguments: ["create", "\(name)"])
            console.info(message)
        } catch ConsoleError.backgroundExecute(_, let message) {
            throw ToolboxError.general("Unable to create Heroku app: \(message.trim())")
        }

        let buildpack: String
        if console.confirm("Would you like to provide a custom Heroku buildpack?") {
            buildpack = console.ask("Custom buildpack:").string ?? ""
        } else {
            buildpack = "https://github.com/kylef/heroku-buildpack-swift"
        }


        console.info("Setting buildpack...")

        do {
            _ = try console.backgroundExecute(program: "heroku", arguments: ["buildpacks:set", "\(buildpack)"])
        } catch ConsoleError.backgroundExecute(_, let message) {
            throw ToolboxError.general("Unable to set buildpack \(buildpack): \(message)")
        }


        let appName: String
        if console.confirm("Are you using a custom Executable name?") {
            appName = console.ask("App Name:").string ?? ""
        } else {
            appName = "App"
        }

        console.info("Setting procfile...")
        let procContents = "web: \(appName) --env=production --workdir=\"./\" --config:servers.default.port=$PORT"
        do {
            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "echo \"\(procContents)\" >> ./Procfile"])
        } catch ConsoleError.backgroundExecute(_, let message) {
            throw ToolboxError.general("Unable to make Procfile: \(message)")
        }

        console.info("Committing procfile...")
        do {
            try gitIsClean() // should throw
        } catch {
          // if not clean, commit.
          _ = try console.backgroundExecute(program: "git", arguments: ["add", "."])
          _ = try console.backgroundExecute(program: "git", arguments: ["commit", "-m",  "'adding procfile'"])
        }

        if console.confirm("Would you like to push to Heroku now?") {
            console.warning("This may take a while...")

            let buildBar = console.loadingBar(title: "Building on Heroku ... ~5-10 minutes")
            buildBar.start()
            do {
              _ = try console.backgroundExecute(program: "git", arguments: ["push", "heroku", "master"])
              buildBar.finish()
            } catch ConsoleError.backgroundExecute(_, let message) {
              buildBar.fail()
              throw ToolboxError.general("Heroku push failed \(message)")
            }

            let dynoBar = console.loadingBar(title: "Spinning up dynos")
            dynoBar.start()
            do {
                _ = try console.backgroundExecute(program: "heroku", arguments: ["ps:scale", "web=1"])
                dynoBar.finish()
            } catch ConsoleError.backgroundExecute(_, let message) {
                dynoBar.fail()
                throw ToolboxError.general("Unable to spin up dynos: \(message)")
            }

            console.print("Visit https://dashboard.heroku.com/apps/")
            console.success("App is live on Heroku.")
        } else {
            console.info("You may push to Heroku later using:")
            console.print("git push heroku master")
            console.warning("Don't forget to scale up dynos:")
            console.print("heroku ps:scale web=1")
        }
    }

}
