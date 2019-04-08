import Vapor
import CloudAPI
import Globals

struct CloudDeploy: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app,
        .env,
        .branch,
        .push,
        .force,
    ]

    /// See `Command`.
    var help: [String] = [
        "Deploys a Vapory Project"
    ]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try CloudDeployRunner(ctx: ctx)
        return try runner.run()
    }
}

struct CloudPush: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app,
        .env,
        .branch,
        .force
    ]

    /// See `Command`.
    var help: [String] = [
        "Pushes your Vapor project to cloud."
    ]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let runner = try CloudPushRunner(ctx: ctx)
        return try runner.run()
    }
}


protocol Runner {
    var ctx: CommandContext { get }
}

protocol AuthorizedRunner: Runner {
    var token: Token { get }
}

extension AuthorizedRunner {

    // Get App

    func loadApp() throws -> EventLoopFuture<CloudApp> {
        let app = try loadCloudApp()
        app.success { app in
            self.ctx.console.output("App: " + app.name.consoleText() + ".")
        }
        return app
    }

    private func loadCloudApp() throws -> EventLoopFuture<CloudApp> {
        todo()
//        let access = CloudApp.Access(with: token, on: ctx.container)
//
//        if let slug = ctx.options.value(.app) {
//            return access.matching(slug: slug)
//        } else if Git.isGitRepository() {
//            return try getAppFromRepository()
//        } else {
//            let apps = access.list()
//            return ctx.select(from: apps)
//        }
    }

    private func getAppFromRepository() throws -> EventLoopFuture<CloudApp> {
        if try Git.isCloudConfigured() {
            return try ctx.detectCloudApp(with: token)
        }

        // Configure App if it Hasn't already
        ctx.console.pushEphemeral()
        var prompt = "There is no cloud app configured with git.\n"
        prompt += "Would you like to set it now?"
        let setNow = ctx.console.confirm(prompt.consoleText())
        ctx.console.popEphemeral()
        // call this again to trigger same error
        guard setNow else { return try ctx.detectCloudApp(with: token) }

        todo()
//        return try RemoteSet().run(using: ctx).flatMap { return try self.ctx.detectCloudApp(with: self.token) }
    }

    // Environment

    func loadEnv(for app: EventLoopFuture<CloudApp>) throws -> EventLoopFuture<CloudEnv> {
        todo()
//        let env = app.flatMap(getDeployEnv)
//        env.success { env in
//            self.ctx.console.output("Environment: " + env.slug.consoleText() + ".")
//        }
//        return env
    }

    private func getDeployEnv(for app: CloudApp) throws -> EventLoopFuture<CloudEnv> {
        todo()
//        let envs = app.environments(with: token, on: ctx.container)
//        return envs.map(self.choose)
    }

    private func choose(from envs: [CloudEnv]) throws -> CloudEnv {
        let envSlug = ctx.options.value(.env)
        if let envSlug = envSlug {
            let possible = envs.first { $0.slug == envSlug }
            guard let env = possible else {
                throw "No environment found matching \(envSlug)."
            }
            return env
        } else if envs.count == 1 {
            return envs[0]
        } else {
            return ctx.console.choose("Which Env?", from: envs) { env in
                return env.slug.consoleText()
            }
        }
    }

    // Branch
    func loadBranch(with env: EventLoopFuture<CloudEnv>, cloudAction: String) throws -> EventLoopFuture<String> {
        todo()
//        let branch = env.map { env -> String in
//            let branch = self.getCloudInteractionBranch(with: env)
//            try self.confirm(branch: branch, cloudAction: cloudAction)
//            return branch
//        }
//
//        branch.success { branch in
//            self.ctx.console.output("Branch: " + branch.consoleText() + ".")
//        }
//
//        return branch
    }

    private func getCloudInteractionBranch(with env: CloudEnv) -> String {
        if let branch = ctx.options.value(.branch) { return branch }
        else { return env.defaultBranch }
    }

    private func confirm(branch: String, cloudAction: String) throws {
        guard Git.isGitRepository() else { return }
        ctx.console.pushEphemeral()
        defer { ctx.console.popEphemeral() }

        // Check uncomitted changes
        try confirmLocalBranch(branch: branch, cloudAction: cloudAction)

        // TODO: Make Enum
        // If we're pushing, obviously don't do this
        guard cloudAction == "deploy" else { return }

        // Check Cloud Upstream
        do {
            let (ahead, behind) = try Git.branch(branch, matchesRemote: "cloud")
            guard ahead || behind else { return }
            var prompt = "".consoleText()
            if ahead && behind {
                prompt += "Local branch "
                prompt += branch.consoleText(.warning)
                prompt += " does NOT MATCH "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else if ahead {
                prompt += "Local branch "
                prompt += branch.consoleText(.warning)
                prompt += " is AHEAD of "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else if behind {
                prompt += "Local branch "
                prompt += branch.consoleText(.warning)
                prompt += " is BEHIND "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else { return }

            prompt += "\n"
            prompt += "Continue?"
            guard ctx.console.confirm(prompt) else { throw "cancelled" }
        } catch {
            var prompt = "Unable to determine if remote ".consoleText()
            prompt += branch.consoleText(.warning)
            prompt += " matches "
            prompt += "cloud/\(branch)".consoleText(.warning)
            prompt += "."
            prompt += "\n"
            prompt += "Continue?"
            guard ctx.console.confirm(prompt) else { throw "cancelled" }
        }
    }

    func confirmLocalBranch(branch: String, cloudAction: String) throws {
        // Check uncomitted changes
        let currentBranch = try Git.currentBranch()
        if currentBranch == branch {
            // Clean only matters on curret branch
            // other branches can't have uncommitted changes
            let isClean = try Git.isClean()
            if !isClean {
                var prompt = "Branch `\(branch)` has uncommitted changes.".consoleText(.warning)
                prompt += "\n"
                prompt += "Continue?"
                guard ctx.console.confirm(prompt) else { throw "cancelled" }
            }
        } else {
            var prompt = "Cloud will \(cloudAction): ".consoleText()
            prompt += "\(branch)".consoleText(.warning)
            prompt += "\n"
            prompt += "You are currently on branch ".consoleText()
            prompt += "\(currentBranch)".consoleText(.warning)
            prompt += "."
            prompt += "\n"
            prompt += "Continue?"
            guard ctx.console.confirm(prompt) else { throw "cancelled" }
        }
    }
}

struct CloudDeployRunner: AuthorizedRunner {
    let ctx: CommandContext
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        todo()
//        self.access = CloudApp.Access(
//            with: token,
//            on: ctx.container
//        )
    }

    func run() throws -> EventLoopFuture<Void> {
        let app = try loadApp()
        let env = try loadEnv(for: app)
        let branch = try loadBranch(with: env, cloudAction: "deploy")

        // If we should push first, insert push operation
        let operation: EventLoopFuture<Void>
        if ctx.flag(.push) {
            let push = try CloudPushRunner(ctx: ctx)
            todo()
//            operation = branch.map(push.push)
            todo()
        } else {
            operation = ctx.done
        }

        // Deploy
        todo()
//        let deploy = operation.flatMap { env.and(branch).flatMap(self.createDeploy) }
//        return deploy.flatMap(monitor)
    }

    private func monitor(_ activity: Activity) throws -> EventLoopFuture<Void> {
        ctx.console.output("Connecting to deploy...")
        todo()
//        return activity.listen(on: ctx.container) { update in
//            switch update {
//            case .connected:
//                // clear connecting
//                self.ctx.console.clear(.line)
//                self.ctx.console.output("Connected to deploy.")
//            case .message(let msg):
//                self.ctx.console.output(msg.consoleText())
//            case .close:
//                self.ctx.console.output("Disconnected.")
//            }
//        }
    }

    private func createDeploy(_ val: (env: CloudEnv, branch: String)) throws -> EventLoopFuture<Activity> {
        todo()
//        return try val.env.deploy(branch: val.branch, with: token, on: ctx.container)
    }
}

extension CommandContext {
    func confirmBranchClean(branch: String) {
        
    }
}

struct CloudPushRunner: AuthorizedRunner {
    let ctx: CommandContext
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        todo()
//        self.access = CloudApp.Access(
//            with: token,
//            on: ctx.container
//        )
    }

    func run() throws -> EventLoopFuture<Void> {
        let app = try loadApp()
        let env = try loadEnv(for: app)
        let branch = try loadBranch(with: env, cloudAction: "push")
        // Deploy
        todo()
//        return branch.map(push)
    }

    func push(branch: String) throws {
        // TODO: Look for uncommitted changes
        guard  try Git.isCloudConfigured() else { throw "Cloud remote not configured." }
        ctx.console.pushEphemeral()
        ctx.console.output("Pushing \(branch)...".consoleText())
        let force = ctx.flag(.force)
        try Git.pushCloud(branch: branch, force: force)
        ctx.console.popEphemeral()
        ctx.console.output("Pushed \(branch).".consoleText())
    }
}

extension EventLoopFuture {
    func success(_ run: @escaping (Value) -> Void) {
        todo()
//        addAwaiter { (result) in
//            guard case .success(let val) = result else { return }
//            run(val)
//        }
    }
}
extension CommandContext {
    func detectCloudApp(with token: Token) throws -> EventLoopFuture<CloudApp> {
        todo()
//        let access = CloudApp.Access(with: token, on: container)
//
//        let cloudGitUrl = try Git.cloudUrl()
//        return access.matching(cloudGitUrl: cloudGitUrl)
    }
}
