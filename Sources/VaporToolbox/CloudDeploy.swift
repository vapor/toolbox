import Vapor

struct CloudDeploy: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        CommandOption
            .value(name: "app", short: "a", default: nil, help: ["The slug associated with your app."]),
//            .value(name: "env", short: "e", default: nil, help: ["The environment to deploy."]),
//            .value(name: "branch", short: "b", default: nil, help: ["A custom branch to deploy if different than the selected environment's default"])

    ]

    /// See `Command`.
    var help: [String] = ["Deploys a Vapory Project"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = try CloudDeployRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudDeployRunner {
    let ctx: CommandContext
    let token: Token

    init(ctx: CommandContext) throws {
        self.ctx = ctx
        self.token = try Token.load()
    }

    func run() throws {
        // Ensure logged in
        let token = try Token.load()

        // Get App
        let app = try cloudApp()
        ctx.console.output("App: " + app.name.consoleText() + ".")

        // Get Env
        let env = try deployEnv(with: app)
        ctx.console.output("Environment: " + env.slug.consoleText() + ".")

        // Get Branch
        let branch = deployBranch(with: env)
        // Confirm Branch
        try confirm(branch: branch)
        ctx.console.output("Branch: " + env.defaultBranch.consoleText() + ".")


        // Deploy
        let deployAccess = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
        let updated = try deployAccess.update(
            id: env.id.uuidString.trailSlash + "deploy",
            with: [
                "branch": branch
            ]
        )

        // Activity
        guard let activity = updated.activity else { throw "no deploy activity found." }
        let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
        ctx.console.pushEphemeral()
        ctx.console.output("Connecting to deploy...")
        let ws = try makeWebSocketClient(url: wssUrl).wait()
        ctx.console.popEphemeral()
        ctx.console.output("Connected to deploy.")

        // Logs
        ws.onText { ws, text in
            self.ctx.console.output(text.consoleText())
        }

        // Close
        try ws.onClose.wait()
        ctx.console.output("Disconnected.")
    }

    func cloudApp() throws -> CloudApp {
        if let slug = ctx.options["app"] {
            let cloudApps = CloudApp.Access(
                with: token,
                baseUrl: applicationsUrl
            )
            let apps = try cloudApps.list(query: "slug=\(slug)")
            guard apps.count == 1 else {
                throw "Unable to find app matching slug: \(slug)."
            }
            return apps[0]
        } else if Git.isGitRepository() {
            return try ctx.detectCloudApp()
        } else {
            let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
            let apps = try access.list()
            ctx.console.pushEphemeral()
            let app = ctx.console.choose("Which App?", from: apps) { app in
                return app.name.consoleText()
            }
            ctx.console.popEphemeral()
            return app
        }
    }

    func deployEnv(with app: CloudApp) throws -> CloudEnv {
        let appEnvsUrl = applicationsUrl.trailSlash
            + app.id.uuidString.trailSlash
            + "environments"
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
        let envs = try envAccess.list()
        if envs.count == 1 { return envs[0] }
        return ctx.console.choose("Which Env?", from: envs) { env in
            return env.slug.consoleText()
        }
    }

    func deployBranch(with env: CloudEnv) -> String {
        if let branch = ctx.options["branch"] { return branch }
        else { return env.defaultBranch }
    }

    func confirm(branch: String) throws {
        guard Git.isGitRepository() else { return }

        // Check uncomitted changes
        let currentBranch = try Git.currentBranch()
        if currentBranch == branch {
            let isClean = try Git.isClean()
            if !isClean {
                var prompt = "\(branch) has uncommitted changes.".consoleText()
                prompt += "\n"
                prompt += "Continue?"

                ctx.console.pushEphemeral()
                let shouldProceed = ctx.console.confirm(prompt)
                ctx.console.popEphemeral()
                guard shouldProceed else { throw "cancelled" }
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

            ctx.console.pushEphemeral()
            let shouldProceed = ctx.console.confirm(prompt)
            ctx.console.popEphemeral()
            guard shouldProceed else { throw "cancelled" }
        }

        // Check Cloud Upstream
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
        }

        prompt += "\n"
        prompt += "Continue?"

        ctx.console.pushEphemeral()
        let shouldProceed = ctx.console.confirm(prompt)
        ctx.console.popEphemeral()
        guard shouldProceed else { throw "cancelled" }
    }
}




// git log --left-right --graph --cherry-pick --oneline cloud-api...origin/cloud-api
// Local is BEHIND remote
// > 8830125 (origin/cloud-api) more deploy work
// Local is AHEAD of remote
// < 5936b4f (HEAD -> cloud-api) more cloud commands
// < d352994 going to test alternative websocket

