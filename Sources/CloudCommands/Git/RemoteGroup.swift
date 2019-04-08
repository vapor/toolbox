import Vapor
import CloudAPI
import Globals

public struct RemoteGroup: CommandGroup {
    public let commands: Commands = [
        "set": RemoteSet(),
        "remove": RemoteRemove(),
    ]

    public let options: [CommandOption] = []

    /// See `CommandGroup`.
    public var help: [String] = [
        "Interacts with git remotes on Vapor Cloud."
    ]

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        ctx.console.info("Interact with git remotes on Vapor Cloud.")
        ctx.console.output("Use `vapor cloud remote -h` to see commands.")
        return ctx.done
    }
}

struct RemoteRemove: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Unlink your local repository from a Cloud app."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        try checkGit()
        try Git.removeRemote(named: "cloud")
        ctx.console.output("Removed Cloud repository.")
        return ctx.done
    }

    func checkGit() throws {
        let isGit = Git.isGitRepository()
        guard isGit else {
            throw "Not currently in a git repository."
        }

        let alreadyConfigured = try Git.isCloudConfigured()
        if !alreadyConfigured {
            throw "No Cloud repository configured."
        }
    }
}

struct RemoteSet: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app
    ]

    /// See `Command`.
    var help: [String] = ["Link your local repository to a Cloud app."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        try checkGit()

        let token = try Token.load()
        todo()
//        let access = CloudApp.Access(with: token, on: ctx.container)
//        let apps = access.list()
//        let app = ctx.select(from: apps)
//        return app.map { app in
//            try Git.setRemote(named: "cloud", url: app.gitURL)
//            ctx.console.output("Cloud repository configured.")
//            // TODO:
//            // Load environments and push branches?
//            ctx.console.pushEphemeral()
//            let push = ctx.console.confirm("Would you like to push to now?")
//            ctx.console.popEphemeral()
//            guard push else { return }
//
//            ctx.console.pushEphemeral()
//            ctx.console.output("Pushing `master` to cloud...")
//            try Git.pushCloud(branch: "master", force: false)
//            ctx.console.popEphemeral()
//            ctx.console.output("Pushed `master` to cloud.")
//        }
    }

    func checkGit() throws {
        let isGit = Git.isGitRepository()
        guard isGit else {
            throw "Not currently in a git repository."
        }

        let alreadyConfigured = try Git.isCloudConfigured()
        guard alreadyConfigured else { return }

        var error = "Cloud is already configured."
        error += "\n"
        error += "Use 'vapor cloud remote remove' and try again."
        throw error
    }
}

extension CommandContext {
    func select(from apps: EventLoopFuture<[CloudApp]>) -> EventLoopFuture<CloudApp> {
        todo()
//        return apps.map { apps in
//            if apps.isEmpty { throw "No apps found, visit https://dashboard.vapor.cloud/apps to create one." }
//            return self.console.choose("Which app?", from: apps) {
//                return $0.name.consoleText()
//            }
//        }
    }
}

