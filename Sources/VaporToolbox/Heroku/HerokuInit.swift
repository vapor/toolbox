import ConsoleKit
import Foundation

let herokuYml = """
build:
  docker:
    web: Dockerfile
"""

let herokuProcfile = """
web: Run serve --env production --hostname 0.0.0.0 --port $PORT
"""

struct HerokuInit: Command {
    struct Signature: CommandSignature { }

    enum Error: Swift.Error, CustomStringConvertible {
        case missingToolbelt
        case remoteAlreadyExists

        var description: String {
            switch self {
            case .missingToolbelt:
                return "Could not find 'heroku' command."
            case .remoteAlreadyExists:
                return "Remote branch 'heroku' already exists."
            }
        }
    }

    let signature = Signature()
    let help = "Configures app for deployment to Heroku."

    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.warning("This command is deprecated. Use `heroku init` instead.")

        // Get Swift package name
        let name = try Process.swift.package.dump().name
        ctx.console.list(key: "Package", value: name)

        // Check if git is clean.
        if try !Process.git.isClean() {
            ctx.console.warning("Git has uncommitted changes.")
        }

        // Check current git branch.
        let branch = try Process.git.currentBranch()
        ctx.console.list(key: "Git branch", value: branch)
        if branch != "master" {
            ctx.console.warning("You are not currently on 'master' branch.")
        }

        // Check for Heroku toolbelt installtion.
        guard Process.shell.programExists("heroku") else {
            ctx.console.list(key: "Install Heroku toolbelt", value: "https://toolbelt.heroku.com")
            throw Error.missingToolbelt
        }

        // Ensure user is logged into Heroku
        do {
            let user = try Process.heroku.run("whoami")
            ctx.console.list(key: "Heroku user", value: user)
        } catch {
            ctx.console.list(.error, key: "Not logged in", value: "Use 'heroku login' to login.")
            throw error
        }

        // Check to see if there's already a `heroku` branch.
        let herokuExists = Process.git.hasRemote(named: "heroku")
        guard !herokuExists else {
            ctx.console.list(.warning, key: "Remove branch", value: "git remote rm heroku")
            throw Error.remoteAlreadyExists
        }

        // Ask for deployment region
        let region: String
        if ctx.console.confirm("Deploy to U.S. region?") {
            region = "us"
        } else {
            region = ctx.console.ask("Region (e.g., us, eu):")
        }

        // Create app and get URL
        ctx.console.output("Creating Heroku app...")
        let url: String
        do {
            url = try Process.heroku.run("create", "--region", region)
                .split(separator: "|")
                .first
                .flatMap(String.init) ?? ""
            ctx.console.output("Heroku app created: ".consoleText(.info) + url.consoleText())
        } catch {
            throw error
        }

        enum Method: String, CustomStringConvertible {
            case docker
            case buildpack
            var description: String {
                self.rawValue
            }
        }

        var createdFiles: [String] = []
        let method = ctx.console.choose("Which deploy method?", from: [Method.docker, Method.buildpack])
        switch method {
        case .buildpack:
            // Add .swift-version configuration file
            if !FileManager.default.fileExists(atPath: "Procfile") {
                let swiftVersion = ctx.console.ask("Which Swift version? (e.g., 5.1)")
                FileManager.default.createFile(
                    atPath: ".swift-version",
                    contents: .init(swiftVersion.utf8)
                )
                createdFiles.append(".swift-version")
                ctx.console.list(.success, key: ".swift-version", value: "Created.")
            } else {
                ctx.console.list(.warning, key: ".swift-version", value: "Already exists.")
            }

            // Add Procfile configuration file
            if !FileManager.default.fileExists(atPath: "Procfile") {
                FileManager.default.createFile(
                    atPath: "Procfile",
                    contents: .init(herokuProcfile.utf8)
                )
                createdFiles.append("Procfile")
                ctx.console.list(.success, key: "Procfile", value: "Created.")
            } else {
                ctx.console.list(.warning, key: "Procfile", value: "Already exists.")
            }

            // Set buildpack
            let buildpack: String
            if ctx.console.confirm("Use default buildpack?") {
                buildpack = "https://github.com/vapor-community/heroku-buildpack"
            } else {
                buildpack = ctx.console.ask("Buildpack URL:")
            }
            ctx.console.output("Setting buildpack...")
            _ = try Process.heroku.run("buildpacks:set", buildpack)

            if FileManager.default.fileExists(atPath: "heroku.yml") {
                ctx.console.error("heroku.yml file will override Procfile")
            }
        case .docker:
            // Verify that Dockerfile exists
            if !FileManager.default.fileExists(atPath: "Dockerfile") {
                ctx.console.warning("No Dockerfile found.")
            }

            // Add heroku.yml configuration file
            if !FileManager.default.fileExists(atPath: "heroku.yml") {
                FileManager.default.createFile(
                    atPath: "heroku.yml",
                    contents: .init(herokuYml.utf8)
                )
                createdFiles.append("heroku.yml")
                ctx.console.list(.success, key: "heroku.yml", value: "Created.")
            } else {
                ctx.console.list(.warning, key: "heroku.yml", value: "Already exists.")
            }

            // Configure container stack
            ctx.console.output("Setting stack...")
            do {
                _ = try Process.heroku.run("stack:set", "container")
            } catch {
                throw error
            }

            if FileManager.default.fileExists(atPath: "Procfile") {
                ctx.console.warning("heroku.yml file will override Procfile")
            }

            ctx.console.warning("You may need to set your app's default port dynamically")
            ctx.console.output("""
            // Support Heroku port
            if let port = Environment.get("PORT").flatMap(Int.init) {
                app.http.server.configuration.port = port
            }
            """)
        }

        if !createdFiles.isEmpty {
            if ctx.console.confirm("Commit changes?") {
                try Process.git.run("add", createdFiles)
                try Process.git.commitChanges(msg: "heroku init")
            } else {
                ctx.console.output("Commit changes then use `\(CommandLine.arguments[0]) heroku push` to deploy.".consoleText())
                return
            }
        }

        if ctx.console.confirm("Deploy now?") {
            try exec(Process.shell.which("git"), "push", "heroku", branch)
            ctx.console.list(.success, key: "Deployed \(name)", value: url)
            ctx.console.output("Use '\(CommandLine.arguments[0]) heroku push' to deploy next time.".consoleText())
        } else {
            ctx.console.output("Use '\(CommandLine.arguments[0]) heroku push' to deploy.".consoleText())
        }
    }
}

