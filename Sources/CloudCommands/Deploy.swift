import ConsoleKit
import CloudAPI
import Globals

struct CloudDeploy: Command {
    struct Signature: CommandSignature {
        let app: Option = .app
        let env: Option = .env
        let branch: Option = .branch
        let push: Option = .push
        let force: Option = .force
    }
    
    let signature = Signature()
    
    let help = "deploy a cloud project."
    
    // command
    func run(using ctx: Context) throws {//} -> EventLoopFuture<Void> {
        let runner = try CloudDeployRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudPush: Command {
    struct Signature: CommandSignature {
        let app: Option = .app
        let env: Option = .env
        let branch: Option = .branch
        let force: Option = .force
    }
    
    let signature = Signature()
    
    let help = "pushes your project to cloud."
    
    /// See `Command`.
    func run(using ctx: Context) throws {
        let runner = try CloudPushRunner(ctx: ctx)
        try runner.run()
    }
}

extension CommandContext {
    func loadApp(with token: Token) throws -> CloudApp {
        let app = try loadCloudApp(with: token)
        console.output("app: " + app.name.consoleText() + ".")
        return app
    }
    
    private func loadCloudApp(with token: Token) throws -> CloudApp {
        let access = CloudApp.Access(with: token)
        if let slug = self.options.value(.app) {
            return try access.matching(slug: slug)
        } else if Git.isGitRepository() {
            return try getAppFromRepository(with: token)
        } else {
            let list = try access.list()
            return try select(from: list)
        }
    }
    
    private func getAppFromRepository(with token: Token) throws -> CloudApp {
        if try Git.isCloudConfigured() {
            return try detectCloudApp(with: token)
        }
        
        // Configure App if it Hasn't already
        console.pushEphemeral()
        var prompt = "there is no cloud app configured with git.\n"
        prompt += "would you like to set it now?"
        let setNow = console.confirm(prompt.consoleText())
        console.popEphemeral()
        // call this again to trigger same error
        guard setNow else { return try detectCloudApp(with: token) }
        
        let ctx = AnyCommandContext(console: console, arguments: arguments, options: options)
        let setter = RemoteSet()
        try setter.run(using: ctx)
        return try detectCloudApp(with: token)
    }
    
    // Environment
    
    func loadEnv(for app: CloudApp, with token: Token) throws -> CloudEnv {
        let env = try getDeployEnv(for: app, with: token)
        console.output("environment: " + env.slug.consoleText() + ".")
        return env
    }
    
    private func getDeployEnv(for app: CloudApp, with token: Token) throws -> CloudEnv {
        let envs = try app.environments(with: token)
        return try self.choose(from: envs)
    }
    
    private func choose(from envs: [CloudEnv]) throws -> CloudEnv {
        let envSlug = options.value(.env)
        if let envSlug = envSlug {
            let possible = envs.first { $0.slug == envSlug }
            guard let env = possible else { throw "no environment found matching \(envSlug)." }
            return env
        } else if envs.count == 1 {
            return envs[0]
        } else {
            return console.choose("which env?", from: envs) { env in
                return env.slug.consoleText()
            }
        }
    }
    
    // Branch
    func loadBranch(with env: CloudEnv, cloudAction: String) throws -> String {
        let branch = getCloudInteractionBranch(with: env)
        try confirm(branch: branch, cloudAction: cloudAction)
        console.output("branch: " + branch.consoleText() + ".")
        return branch
    }
    
    private func getCloudInteractionBranch(with env: CloudEnv) -> String {
        if let branch = options.value(.branch) { return branch }
        else { return env.defaultBranch }
    }
    
    private func confirm(branch: String, cloudAction: String) throws {
        guard Git.isGitRepository() else { return }
        console.pushEphemeral()
        defer { console.popEphemeral() }
        
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
                prompt += "local branch "
                prompt += branch.consoleText(.warning)
                prompt += " does NOT MATCH "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else if ahead {
                prompt += "local branch "
                prompt += branch.consoleText(.warning)
                prompt += " is AHEAD of "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else if behind {
                prompt += "local branch "
                prompt += branch.consoleText(.warning)
                prompt += " is BEHIND "
                prompt += "cloud/\(branch)".consoleText(.warning)
                prompt += "."
            } else { return }
            
            prompt += "\n"
            prompt += "continue?"
            guard console.confirm(prompt) else { throw "cancelled" }
        } catch {
            var prompt = "unable to determine if remote ".consoleText()
            prompt += branch.consoleText(.warning)
            prompt += " matches "
            prompt += "cloud/\(branch)".consoleText(.warning)
            prompt += "."
            prompt += "\n"
            prompt += "continue?"
            guard console.confirm(prompt) else { throw "cancelled" }
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
                var prompt = "branch `\(branch)` has uncommitted changes.".consoleText(.warning)
                prompt += "\n"
                prompt += "continue?"
                guard console.confirm(prompt) else { throw "cancelled" }
            }
        } else {
            var prompt = "cloud will \(cloudAction): ".consoleText()
            prompt += "\(branch)".consoleText(.warning)
            prompt += "\n"
            prompt += "you are currently on branch ".consoleText()
            prompt += "\(currentBranch)".consoleText(.warning)
            prompt += "."
            prompt += "\n"
            prompt += "continue?"
            guard console.confirm(prompt) else { throw "cancelled" }
        }
    }
}

struct CloudDeployRunner<C: CommandRunnable> {
    let ctx: CommandContext<C>
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext<C>) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        self.access = CloudApp.Access(with: token)
    }

    func run() throws {
        let app = try ctx.loadApp(with: token)
        let env = try ctx.loadEnv(for: app, with: token)
        let branch = try ctx.loadBranch(with: env, cloudAction: "deploy")

        // ff we should push first, insert push operation
        if ctx.flag(.push) {
            let push = try CloudPushRunner(ctx: ctx)
            try push.push(branch: branch)
        }

        let deploy = try createDeploy((env, branch))
        try monitor(deploy)
    }

    private func monitor(_ activity: Activity) throws {
        ctx.console.output("connecting to deploy...")
        try activity.listen { update in
            switch update {
            case .connected:
                // clear connecting
                self.ctx.console.clear(.line)
                self.ctx.console.output("connected to deploy.")
            case .message(let msg):
                self.ctx.console.output(msg.consoleText())
            case .close:
                self.ctx.console.output("disconnected.")
            }
        }
    }

    private func createDeploy(_ val: (env: CloudEnv, branch: String)) throws -> Activity {
        return try val.env.deploy(branch: val.branch, with: token)
    }
}

struct CloudPushRunner<C: CommandRunnable> {
    let ctx: CommandContext<C>
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext<C>) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        self.access = CloudApp.Access(with: token)
    }

    func run() throws {
        let app = try ctx.loadApp(with: token)
        let env = try ctx.loadEnv(for: app, with: token)
        let branch = try ctx.loadBranch(with: env, cloudAction: "push")
        // push
        try push(branch: branch)
    }

    func push(branch: String) throws {
        // TODO: Look for uncommitted changes
        guard  try Git.isCloudConfigured() else { throw "cloud remote not configured." }
        ctx.console.pushEphemeral()
        ctx.console.output("pushing \(branch)...".consoleText())
        let force = ctx.flag(.force)
        try Git.pushCloud(branch: branch, force: force)
        ctx.console.popEphemeral()
        ctx.console.output("pushed \(branch).".consoleText())
    }
}

extension CommandContext {
    func detectCloudApp(with token: Token) throws -> CloudApp {
        let access = CloudApp.Access(with: token)
        let cloudGitUrl = try Git.cloudUrl()
        return try access.matching(cloudGitUrl: cloudGitUrl)
    }
}
