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

        do {
            let message = try console.subexecute("heroku create \(name)")
            console.info(message)
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

        let procContents = "web: App --env=production --workdir=\"./\""
        do {
            _ = try console.subexecute("echo \"\(procContents)\" > ./Procfile")
        } catch ConsoleError.subexecute(_, let message) {
            throw Error.general("Unable to make Procfile: \(message)")
        }

        if console.confirm("Would you like to push to Heroku now?") {
            console.warning("This may take a while...")

            let push = HerokuPush(console: console)
            try push.run(arguments: [])

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
