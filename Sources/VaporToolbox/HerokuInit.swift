import Console

public final class HerokuInit: Command {
    public let id = "init"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Prepares the application for Heroku integration."
    ]

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        do {
            _ = try console.subexecute("which heroku")
        } catch ConsoleError.subexecute(_, _) {
            console.info("Visit https://toolbelt.heroku.com")
            throw Error.general("Heroku Toolbelt must be installed.")
        }

        do {
            let status = try console.subexecute("git status --porcelain")
            if status.trim() != "" {
                console.info("All current changes must be committed before pushing to Heroku.")
                throw Error.general("Found uncommitted changes.")
            }
        } catch ConsoleError.subexecute(_, _) {
            throw Error.general("No .git repository found.")
        }

        do {
            _ = try console.subexecute("git remote show heroku")
            throw Error.general("Git already has a heroku remote.")
        } catch ConsoleError.subexecute(_, _) {
            //continue
        }

        let name: String
        if console.confirm("Would you like to provide a custom Heroku app name?") {
            name = console.ask("Custom app name:").string ?? ""
        } else {
            name = ""
        }

        console.info("Creating \(name ?? "Heroku app")...")

        do {
            _ = try console.subexecute("heroku create \(name)")
        } catch ConsoleError.subexecute(_, let message) {
            throw Error.general("Unable to create Heroku app: \(message.trim())")
        }

        let buildpack: String
        if console.confirm("Would you like to provide a custom Heroku buildpack?") {
            buildpack = console.ask("Custom buildpack:").string ?? ""
        } else {
            buildpack = "https://github.com/kylef/heroku-buildpack-swift"
        }


        console.info("Setting buildpack...")

        do {
            _ = try console.subexecute("heroku buildpacks:set \(buildpack)")
        } catch ConsoleError.subexecute(_, let message) {
            throw Error.general("Unable to set buildpack \(buildpack): \(message)")
        }

        console.info("Creating procfile...")

        let procContents = "web: App --port=\\$PORT"
        do {
            _ = try console.subexecute("echo \"\(procContents)\" > ./Procfile")
        } catch ConsoleError.subexecute(_, let message) {
            throw Error.general("Unable to make Procfile: \(message)")
        }

        if console.confirm("Would you like to push to Heroku now?") {
            console.warning("This may take a while...")
            let herokuBar = console.loadingBar(title: "Pushing to Heroku")
            herokuBar.start()
            do {
                _ = try console.subexecute("git add . && git commit -m 'vapor toolbox initializing heroku' && git push heroku master")
                herokuBar.finish()
            } catch ConsoleError.subexecute(_, let message) {
                herokuBar.fail()
                throw Error.general("Unable to push to Heroku: \(message)")
            }

            let dynoBar = console.loadingBar(title: "Spinning up dynos")
            dynoBar.start()

            do {
                _ = try console.subexecute("heroku ps:scale web=1")
                dynoBar.finish()
            } catch ConsoleError.subexecute(_, let message) {
                dynoBar.fail()
                throw Error.general("Unable to spin up dynos: \(message)")
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
