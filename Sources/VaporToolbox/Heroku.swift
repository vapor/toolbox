import ConsoleKit
import Globals
import Foundation

/// Cleans temporary files created by Xcode and SPM.
struct Heroku: Command {
    struct Signature: CommandSignature {
        @Flag(name: "update", short: "u", help: "cleans Package.resolved file if it exists.")
        var update: Bool
        @Flag(name: "keep-checkouts", short: "k", help: "keep git checkouts of dependencies.")
        var keepCheckouts: Bool
    }
    let signature = Signature()
    let help = "Configures app for deployment to Heroku."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        guard try Git.isClean() else {
            // force this because we're going to be adding commits
            throw "git status not clean, all changes must be committed before initing heroku."
        }

        let branch = try Git.currentBranch()
        guard branch == "master" else {
            throw "please checkout master branch before initializing heroku. 'git checkout master'"

        }

        do {
            try Shell.programExists("heroku")
        } catch _ as String {
            // only catch our internal errors
            ctx.console.info("visit https://toolbelt.heroku.com")
            throw "heroku toolbelt must be installed."
        }

        let herokuExists = Git.hasRemote(named: "heroku")
        guard !herokuExists else {
            throw """
            this project is already configured to an existing heroku app.
            if you'd like to use this project with a new heroku app, use

            'git remote remove heroku'

            and try again.
            """
        }

        do {
            let user = try HerokuInterface.run("auth:whoami")
            ctx.console.output("Logged in as ".consoleText(.plain) + user.consoleText(.info))
        } catch {
            ctx.console.info("Use heroku auth:login")
            throw "Not logged in to Heroku"
        }

        let name: String
        if ctx.console.confirm("Use a custom Heroku app identifier?") {
            name = ctx.console.ask("Custom app identifier:")
        } else {
            name = ""
        }

        let region: String
        if ctx.console.confirm("Deploy to a region other than the us?") {
            region = ctx.console.ask("Custom region (ie: us, eu):")
        } else {
            region = "us"
        }
        let url: String
        do {
            url = try HerokuInterface.run("create", name, "--region", region)
            ctx.console.output("Heroku app created at: ".consoleText() + url.consoleText(.info))
        } catch {
            throw "Unable to create heroku app: \(error)"
        }

        let buildpack: String
        if ctx.console.confirm("Use a custom Heroku buildpack?") {
            buildpack = ctx.console.ask("Custom buildpack url:")
        } else {
            buildpack = "https://github.com/vapor-community/heroku-buildpack"
        }

        ctx.console.info("Setting buildpack...")

        do {
            _ = try HerokuInterface.run("buildpacks:set", buildpack)
        } catch {
            throw "Unable to set buildpack \(buildpack): \(error)"
        }


        let vaporAppName: String
        if ctx.console.confirm("Use a custom executable name?") {
            vaporAppName = ctx.console.ask("Executable name:")
        } else {
            vaporAppName = "Run"
        }

        ctx.console.info("Creating procfile...")
        let procContents = "web: \(vaporAppName) serve --env production --hostname 0.0.0.0 --port \\$PORT"
        do {
            try Shell.bash("echo \(procContents) > ./Procfile")
        } catch {
            throw "unable to make procfile: \(error)"
        }

        guard !(try Git.isClean()) else {
            throw "there was an error adding the procfile"
        }

//        ctx.console.info("staging procfile...")
        try Git.addChanges()
//        ctx.console.info("committing procfile...")
        try Git.commitChanges(msg: "adding heroku procfile")

        let swiftVersion = ctx.console.ask("Which swift version (ie: 5.1)?")
        ctx.console.info("Setting swift version...")
        do {
            try Shell.bash("echo \(swiftVersion) > ./.swift-version")
        } catch {
            throw "Unable to set swift version: \(error)"
        }

        guard !(try Git.isClean()) else {
            throw "there was an error setting the swift version"
        }

//        ctx.console.info("staging procfile...")
        try Git.addChanges()
//        ctx.console.info("committing procfile...")
        try Git.commitChanges(msg: "adding swift version")

        // todo push to heroku
        ctx.console.success("you are now ready, call `git push heroku master` to deploy.")
//
//        if console.confirm("Would you like to push to Heroku now?") {
//            console.warning("This may take a while...")
//
//            let buildBar = console.loadingBar(title: "Building on Heroku ... ~5-10 minutes", animated: !arguments.isVerbose)
//            buildBar.start()
//            do {
//                _ = try console.execute(verbose: arguments.isVerbose, program: "git", arguments: ["push", "heroku", "master"])
//                buildBar.finish()
//            } catch ConsoleError.backgroundExecute(_, let message, _) {
//                buildBar.fail()
//                throw ToolboxError.general("Heroku push failed \(message)")
//            } catch {
//                // prevents foreground executions from logging 'Done' instead of 'Failed'
//                buildBar.fail()
//                throw error
//            }
//
//            let dynoBar = console.loadingBar(title: "Spinning up dynos", animated: !arguments.isVerbose)
//            dynoBar.start()
//            do {
//                _ = try console.execute(verbose: arguments.isVerbose, program: "heroku", arguments: ["ps:scale", "web=1"])
//                dynoBar.finish()
//            } catch ConsoleError.backgroundExecute(_, let message, _) {
//                dynoBar.fail()
//                throw ToolboxError.general("Unable to spin up dynos: \(message)")
//            } catch {
//                // prevents foreground executions from logging 'Done' instead of 'Failed'
//                dynoBar.fail()
//                throw error
//            }
//
//            console.print("Visit https://dashboard.heroku.com/apps/")
//            console.success("App is live on Heroku, visit \n\(url)")
//        } else {
//            console.info("You may push to Heroku later using:")
//            console.print("git push heroku master")
//            console.warning("Don't forget to scale up dynos:")
//            console.print("heroku ps:scale web=1")
//        }
//    }
    }
}

/*

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
         let procContents = "web: \(appName) --env=production --port=\\$PORT"
         do {
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
 */

struct HerokuInterface {
    @discardableResult
    public static func run(_ args: String...) throws -> String {
        return try Process.backgroundRun("heroku", args: args)
    }
}
