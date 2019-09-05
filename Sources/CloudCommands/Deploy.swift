import ConsoleKit
import CloudAPI
import Globals

struct CloudDeploy: Command {
    struct Signature: CommandSignature {
        @Option(name: "app", short: "a")
        var app: String
        @Option(name: "env", short: "e")
        var env: String
        @Option(name: "branch", short: "b")
        var branch: String
        @Flag(name: "force", short: "f")
        var force: Bool
        @Flag(name: "push", short: "p")
        var push: Bool
    }
    
    let signature = Signature()
    
    let help = "deploy a cloud project."
    
    // command
    func run(using ctx: CommandContext, signature: Signature) throws {//} -> EventLoopFuture<Void> {
        let runner = try CloudDeployRunner(ctx: ctx, sig: signature)
        try runner.run()
    }
}

struct CloudPush: Command {
    struct Signature: CommandSignature {
        @Option(name: "app", short: "a")
        var app: String
        @Option(name: "env", short: "e")
        var env: String
        @Option(name: "branch", short: "b")
        var branch: String
        @Flag(name: "force", short: "f")
        var force: Bool
    }

    let help = "pushes your project to cloud."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let runner = try CloudPushRunner(ctx: ctx)
        try runner.run()
    }
}

protocol AppSignature {
    var app: String? { get }
}
protocol EnvSignature {
    var env: String? { get }
}
protocol BranchSignature {
    var branch: String? { get }
}

fileprivate struct _AppSignature: CommandSignature {
    @Option(name: "app", short: "a")
    var app: String
}


fileprivate struct _EnvSignature: CommandSignature {
    @Option(name: "env", short: "e")
    var env: String
}


fileprivate struct _BranchSignature: CommandSignature {
    @Option(name: "branch", short: "b")
    var branch: String
}

fileprivate struct _ForceSignature: CommandSignature {
    @Flag(name: "force", short: "f")
    var force: Bool
}
fileprivate struct _PushSignature: CommandSignature {
    @Flag(name: "push", short: "p")
    var push: Bool
}

extension CommandContext {
    var enteredApp: String? {
        return try? input.make(_AppSignature.self).app
    }

    var enteredEnv: String? {
        return try? input.make(_EnvSignature.self).env
    }

    var enteredBranch: String? {
        return try? input.make(_EnvSignature.self).env
    }

    var force: Bool {
        return (try? input.make(_ForceSignature.self).force) ?? false
    }

    var push: Bool {
        return (try? input.make(_PushSignature.self).push) ?? false
    }
}

extension CommandInput {
    func make<S: CommandSignature>(_ type: S.Type = S.self) throws -> S {
        var copy = self
        return try S(from: &copy)
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
        if let slug = self.enteredApp {
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

//        let sig = RemoteSet.Signature()
//
//        var opt: CommandContext! = nil
//        RemoteSet.Signature.init(from: &opt)
//        self.input.arguments

        var copy = self
        let setter = RemoteSet()
        try setter.run(using: &copy)
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
        if let envSlug = self.enteredEnv {
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
        if let branch = self.enteredBranch { return branch }
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

struct CloudDeployRunner {
    let ctx: CommandContext
    let signature: CloudDeploy.Signature
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext, sig: CloudDeploy.Signature) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.token = token
        self.signature = sig
        self.access = CloudApp.Access(with: token)
    }

    func run() throws {
        let app = try ctx.loadApp(with: token)
        let env = try ctx.loadEnv(for: app, with: token)
        let branch = try ctx.loadBranch(with: env, cloudAction: "deploy")

        // ff we should push first, insert push operation
        if ctx.push {
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


struct CloudPushAction {
    let ctx: CommandContext
    let signature: CloudPush.Signature
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext, signature: CloudPush.Signature) throws {
        let token = try Token.load()

        self.ctx = ctx
        self.signature = signature
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
        let force = ctx.force
        try Git.pushCloud(branch: branch, force: force)
        ctx.console.popEphemeral()
        ctx.console.output("pushed \(branch).".consoleText())
    }
}

struct CloudPushRunner {
    let ctx: CommandContext
    let token: Token
    let access: ResourceAccess<CloudApp>

    init(ctx: CommandContext) throws {
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
        let force = ctx.force
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
