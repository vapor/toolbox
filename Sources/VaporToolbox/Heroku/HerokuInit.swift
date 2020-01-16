import ConsoleKit
import Foundation

struct HerokuInit: Command {
    struct Signature: CommandSignature {
        @Flag(name: "update", short: "u", help: "cleans Package.resolved file if it exists.")
        var update: Bool
        @Flag(name: "keep-checkouts", short: "k", help: "keep git checkouts of dependencies.")
        var keepCheckouts: Bool
    }
    let signature = Signature()
    let help = "Configures an app for deployment to Heroku."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        guard try Process.git.isClean() else {
            // force this because we're going to be adding commits
            throw "git status not clean, all changes must be committed before initing heroku."
        }

        let branch = try Process.git.currentBranch()
        guard branch == "master" else {
            throw "please checkout master branch before initializing heroku. 'git checkout master'"

        }

        guard Shell.default.programExists("heroku") else {
            ctx.console.info("visit https://toolbelt.heroku.com")
            throw "heroku toolbelt must be installed."
        }

        let herokuExists = Process.git.hasRemote(named: "heroku")
        guard !herokuExists else {
            throw """
            this project is already configured to an existing heroku app.
            if you'd like to use this project with a new heroku app, use

            'git remote remove heroku'

            and try again.
            """
        }

        let name: String
        if ctx.console.confirm("should we use a custom heroku app identifier?") {
            name = ctx.console.ask("custom app identifier:")
        } else {
            name = ""
        }

        let region: String
        if ctx.console.confirm("should we deploy to a region other than the us?") {
            region = ctx.console.ask("custom region (ie: us, eu):")
        } else {
            region = "us"
        }


        let url: String
        do {
            url = try Process.heroku.run("create", name, "--region", region)
            ctx.console.info("heroku app created at:")
            ctx.console.info(url)
        } catch {
            ctx.console.error("unable to create heroku app:")
            throw error
        }

        let buildpack: String
        if ctx.console.confirm("should we use a custom Heroku buildpack?") {
            buildpack = ctx.console.ask("custom buildpack url:")
        } else {
            buildpack = "https://github.com/vapor-community/heroku-buildpack"
        }

        ctx.console.info("setting buildpack...")

        do {
            _ = try Process.heroku.run("buildpacks:set", buildpack)
        } catch {
            ctx.console.error("unable to set buildpack \(buildpack):")
            throw error
        }


        let vaporAppName: String
        if ctx.console.confirm("is your vapor app using a custom executable name?") {
            vaporAppName = ctx.console.ask("executable name:")
        } else {
            vaporAppName = "Run"
        }

        ctx.console.info("setting procfile...")
        let procContents = "web: \(vaporAppName) serve --env production --hostname 0.0.0.0 --port \\$PORT"
        do {
            _ = try Process.run("echo", "\(procContents) >> ./Procfile")
        } catch {
            ctx.console.error("unable to make procfile")
            throw error
        }

        guard !(try Process.git.isClean()) else {
            throw "there was an error adding the procfile"
        }

        try Process.git.addChanges()
        try Process.git.commitChanges(msg: "adding heroku procfile")

        let swiftVersion = ctx.console.ask("which swift version should we use (ie: 5.1)?")
        ctx.console.info("setting swift version...")
        do {
            try Process.run("echo", "\(swiftVersion) >> ./.swift-version")
        } catch {
            ctx.console.error("unable to set swift versiono")
            throw error
        }

        guard !(try Process.git.isClean()) else {
            throw "there was an error setting the swift version"
        }

        try Process.git.addChanges()
        try Process.git.commitChanges(msg: "adding swift version")

        // todo push to heroku
        ctx.console.success("you are now ready, call `git push heroku master` to deploy.")
    }
}

