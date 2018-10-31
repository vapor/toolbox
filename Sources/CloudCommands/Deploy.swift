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
            on: ctx.container
        )
    }

    func run() throws -> Future<Void> {
        // Get App
        let app = try getDeployApp()
        app.success { app in
            self.ctx.console.output("App: " + app.name.consoleText() + ".")
        }

        // Get Env
        let env = app.flatMap(getDeployEnv)
        env.success { env in
            self.ctx.console.output("Environment: " + env.slug.consoleText() + ".")
        }

        // Get Branch
        let branch = env.map(getDeployBranch)
        branch.success { branch in
            self.ctx.console.output("Branch: " + branch.consoleText() + ".")
        }

        
        let sd = env.and(branch).flatMap { val in
            return self.triggerDeploy(val.0, branch: val.1)
        }
//        let deploy = env.flatMap { env -> Future<CloudEnv> in
//            self.ctx.console.output("Environment: " + env.slug.consoleText() + ".")
//            let branch = self.getDeployBranch(with: env)
//
//            // Confirm Branch
//            try self.confirm(branch: branch)
//            self.ctx.console.output("Branch: " + branch + ".")
//
//            // Deploy
//            return self.deploy(env, branch: branch)
//        }

        return sd.flatMap { env in
            return try self.deployActivity(for: env)
        }
    }

    private func deployActivity(for env: CloudEnv) throws -> Future<Void> {
        // Activity
        guard let activity = env.activity else { throw "No deploy activity found." }
        ctx.console.output("Connecting to deploy...")
        return activity.listen(on: ctx.container) { update in
            switch update {
            case .connected:
                // clear connecting
                self.ctx.console.clear(.line)
                self.ctx.console.output("Connected to deploy.")
            case .message(let msg):
                self.ctx.console.output(msg.consoleText())
            case .close:
                self.ctx.console.output("Disconnected.")
            }
        }
    }

    private func triggerDeploy(_ env: CloudEnv, branch: String) -> Future<CloudEnv> {
        let deployAccess = CloudEnv.Access(with: self.token, baseUrl: environmentsUrl, on: ctx.container)
        return deployAccess.update(
            id: env.id.uuidString.finished(with: "/") + "deploy",
            with: [
                "branch": branch
            ]
        )
    }

    private func getDeployEnv(for app: CloudApp) throws -> Future<CloudEnv> {
        let envs = app.environments(with: token, on: ctx.container)
        return envs.map(self.choose)
    }
    
    private func getDeployApp() throws -> Future<CloudApp> {
        if let slug = ctx.options.value(.app) {
            return access.matching(slug: slug)
        } else if Git.isGitRepository() {
            return try ctx.detectCloudApp(with: token)
        } else {
            return access.list().map { apps in
                let app = self.ctx.console.choose("Which App?", from: apps) { app in
                    return app.name.consoleText()
                }
                return app
            }
        }
    }

    private func deployEnv(with app: CloudApp) throws -> CloudEnv {
        fatalError()
        // Collect Envs
//        let appEnvsUrl = applicationsUrl.trailSlash
//            + app.id.uuidString.trailSlash
//            + "environments"
//        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
//        let envs = try envAccess.list()
//
//        // Select
//        let envSlug = ctx.options["env"]
//        if let envSlug = envSlug {
//            let possible = envs.first { $0.slug == envSlug }
//            guard let env = possible else {
//                throw "No environment found matching \(envSlug)"
//            }
//            return env
//        } else if envs.count == 1 {
//            return envs[0]
//        } else {
//            return ctx.console.choose("Which Env?", from: envs) { env in
//                return env.slug.consoleText()
//            }
//        }
    }

    private func _deployEnv(with app: CloudApp) throws -> Future<CloudEnv> {
        
        // Collect Envs
//        let appEnvsUrl = environmentUrl(with: app)
//        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl, on: ctx.container)
//        let envs = envAccess.list()
//        return envs.map(self.choose)
        fatalError()
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

    private func getDeployBranch(with env: CloudEnv) -> String {
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

extension Future {
    func success(_ run: @escaping (T) -> Void) {
        addAwaiter { (result) in
            guard case .success(let val) = result else { return }
            run(val)
        }
    }
}
extension CommandContext {
    func detectCloudApp(with token: Token) throws -> Future<CloudApp> {
        let access = CloudApp.Access(with: token, on: container)

        let cloudGitUrl = try Git.cloudUrl()
        return access.matching(cloudGitUrl: "gitURL=\(cloudGitUrl)")
    }
}
