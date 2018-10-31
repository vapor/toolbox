import Vapor
import CloudAPI

struct CloudDeploy: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .app,
        .env,
        .branch
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

struct CloudDeployRunner {
    let ctx: CommandContext
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        self.access = CloudApp.Access(
            with: token,
            baseUrl: applicationsUrl,
            on: ctx.container
        )
    }

    func run() throws -> Future<Void> {
        // Get App
        let app = try cloudApp()
        let env = app.flatMap { app -> Future<CloudEnv> in
            self.ctx.console.output("App: " + app.name.consoleText() + ".")
            return try self.deployEnv(with: app)
        }

        let deploy = env.flatMap { env -> Future<CloudEnv> in
            self.ctx.console.output("Environment: " + env.slug.consoleText() + ".")
            let branch = self.deployBranch(with: env)
            // Confirm Branch
            try self.confirm(branch: branch)
            self.ctx.console.output("Branch: " + env.defaultBranch.consoleText() + ".")

            // Deploy
            return self.deploy(env, branch: branch)
        }

        return deploy.flatMap { env in
            return try self.deployActivity(for: env)
        }
//
//        // Get Env
//        let env = try deployEnv(with: app)
//        ctx.console.output("Environment: " + env.slug.consoleText() + ".")
//
//        // Get Branch
//        let branch = deployBranch(with: env)
//        // Confirm Branch
//        try confirm(branch: branch)
//        ctx.console.output("Branch: " + env.defaultBranch.consoleText() + ".")
//
//
//        // Deploy
//        let deployAccess = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
//        let updated = try deployAccess.update(
//            id: env.id.uuidString.trailSlash + "deploy",
//            with: [
//                "branch": branch
//            ]
//        )
//
//        // Activity
//        guard let activity = updated.activity else { throw "no deploy activity found." }
//        let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
//        ctx.console.pushEphemeral()
//        ctx.console.output("Connecting to deploy...")
//        let ws = try makeWebSocketClient(url: wssUrl).wait()
//        ctx.console.popEphemeral()
//        ctx.console.output("Connected to deploy.")
//
//        // Logs
//        ws.onText { ws, text in
//            self.ctx.console.output(text.consoleText())
//        }
//
//        // Close
//        try ws.onClose.wait()
//        ctx.console.output("Disconnected.")
    }

    private func deployActivity(for env: CloudEnv) throws -> Future<Void> {
        // Activity
        guard let activity = env.activity else { throw "No deploy activity found." }
        let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
        ctx.console.pushEphemeral()
        ctx.console.output("Connecting to deploy...")

        let ws = makeWebSocketClient(url: wssUrl, on: ctx.container)
        return ws.flatMap { ws in
            self.ctx.console.popEphemeral()
            self.ctx.console.output("Connected to deploy.")

            // Logs
            ws.onText { ws, text in
                self.ctx.console.output(text.consoleText())
            }

            // Close
            return ws.onClose.map {
                self.ctx.console.output("Disconnected.")
            }
        }
    }

    private func deploy(_ env: CloudEnv, branch: String) -> Future<CloudEnv> {
        let deployAccess = CloudEnv.Access(with: self.token, baseUrl: environmentsUrl, on: ctx.container)
        return deployAccess.update(
            id: env.id.uuidString.finished(with: "/") + "deploy",
            with: [
                "branch": branch
            ]
        )
    }

    private func cloudApp() throws -> Future<CloudApp> {
        if let slug = ctx.options.value(.app) {
            let apps = access.list(query: "slug=\(slug)")
            return apps.map { apps in
                guard apps.count == 1 else {
                    throw "Unable to find app matching slug: \(slug)."
                }
                return apps[0]
            }
        } else if Git.isGitRepository() {
            return try ctx.detectCloudApp(with: token)
        } else {
            let apps = access.list()
            return apps.map { apps in
//                self.ctx.console.pushEphemeral()
                let app = self.ctx.console.choose("Which App?", from: apps) { app in
                    return app.name.consoleText()
                }
//                self.ctx.console.popEphemeral()
                return app
            }
        }
    }

    private func deployEnv(with app: CloudApp) throws -> Future<CloudEnv> {
        // Collect Envs
        let appEnvsUrl = environmentUrl(with: app)
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl, on: ctx.container)
        let envs = envAccess.list()
        return envs.map(self.choose)
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

    private func deployBranch(with env: CloudEnv) -> String {
        if let branch = ctx.options.value(.branch) { return branch }
        else { return env.defaultBranch }
    }

    private func confirm(branch: String) throws {
        guard Git.isGitRepository() else { return }
        ctx.console.pushEphemeral()
        defer { ctx.console.popEphemeral() }

        // Check uncomitted changes
        let currentBranch = try Git.currentBranch()
        if currentBranch == branch {
            let isClean = try Git.isClean()
            if !isClean {
                var prompt = "\(branch) has uncommitted changes.".consoleText()
                prompt += "\n"
                prompt += "Continue?"
                guard ctx.console.confirm(prompt) else { throw "cancelled" }
            }
        } else {
            var prompt = "Cloud will deploy: ".consoleText()
            prompt += "\(branch)".consoleText(.warning)
            prompt += "\n"
            prompt += "You are currently on branch ".consoleText()
            prompt += "\(currentBranch)".consoleText(.warning)
            prompt += "."
            prompt += "\n"
            prompt += "Continue?"
            guard ctx.console.confirm(prompt) else { throw "cancelled" }
        }

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
}

extension CommandContext {
    func detectCloudApp(with token: Token) throws -> Future<CloudApp> {
        let cloudGitUrl = try Git.cloudUrl()

        let access = CloudApp.Access(with: token, baseUrl: applicationsUrl, on: container)
        let apps = access.list(query: "gitURL=\(cloudGitUrl)")
        return apps.map { apps in
            guard apps.count == 1 else { throw "No app found at \(cloudGitUrl)." }
            return apps[0]
        }
    }
}
