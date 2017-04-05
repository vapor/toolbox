import Shared

public final class DeployCloud: Command {
    public let id = "deploy"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Deploy a project to Vapor Cloud"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        // vapor cloud deploy --repo=app.foo
        try console.warnGitClean()

        // drop 'deploy' from argument list
        let arguments = arguments.dropFirst().array
        let token = try Token.global(with: console)

        let repo = try getRepo(arguments, with: token)

        let env = try selectEnvironment(
            args: arguments,
            forRepo: repo,
            queryTitle: "Which Environment?",
            using: console,
            with: token
        )

        console.print("Deploying Environment: ", newLine: false)
        console.info("\(env.name)")
        let replicas = getReplicas(arguments)
        let hosting = try getHosting(forRepo: repo, with: token)
        let branch = try getBranch(arguments, gitUrl: hosting.gitUrl, env: env)

        if gitInfo.isGitProject(), let matchingRemote = try gitInfo.remote(forUrl: hosting.gitUrl) {
            // verify there's not uncommitted changes
            try verify(deployBranch: branch, remote: matchingRemote)
        }

        let buildType = try getBuildType(arguments)

        /// Deploy
        let deployBar = console.loadingBar(title: "Deploying")
        let deploy = try deployBar.perform {
            return try applicationApi.deploy.push(
                repo: repo,
                envName: env.name,
                gitBranch: branch,
                replicas: replicas,
                code: buildType,
                with: token
            )
        }

        /// No output for scale apis
        if let _ = deploy.deployments.lazy.filter({ $0.type == .scale }).first {
            let scaleBar = console.loadingBar(title: "Scaling", animated: false)
            scaleBar.finish()
        }

        /// Build Logs
        guard let code = deploy.deployments.lazy.filter({ $0.type == .code }).first else { return }
        console.info("Connecting to build logs ...")
        var waitingInQueue = console.loadingBar(title: "Waiting in Queue")
        defer { waitingInQueue.fail() }
        waitingInQueue.start()

        var logsBar: LoadingBar?
        try Redis.subscribeDeployLog(id: code.id.uuidString) { update in
            waitingInQueue.finish()

            if update.type == .start {
                logsBar = self.console.loadingBar(title: update.message)
                logsBar?.start()
            } else if update.success {
                logsBar?.finish()
            } else {
                logsBar?.fail()
            }

            if !update.success && !update.message.trim().isEmpty {
                let printable = update.message
                    .components(separatedBy: "BREAK")
                    .joined(separator: "\n")
                self.console.warning(printable)
                throw "deploy failed."
            }
        }

        console.success("Successfully deployed.")
    }

    private func getBuildType(_ arguments: [String]) throws -> BuildType {
        if let option = arguments.option("build") ?? localConfig?["buildType"]?.string {
            guard let buildType = BuildType(rawValue: option) else {
                console.warning("Unrecognized build type \(option)")
                let buildTypes = BuildType.all.map { $0.rawValue }.joined(separator: ", ")
                throw "Use one of \(buildTypes)"
            }

            return buildType
        }

        return try console.giveChoice(
            title: "Build type?",
            in: [
                BuildType.clean,
                BuildType.incremental,
                BuildType.update
            ]
        )
    }

    private func getRepo(_ arguments: [String], with token: Token) throws -> String {
        let localConfig = try LocalConfig.load()
        if let repo = arguments.option("repo") ?? localConfig["app.repo"]?.string {
            return repo
        }

        if gitInfo.isGitProject() {
            let apps = try gitInfo
                .remotes()
                .flatMap { remote -> [Application] in
                    guard let resolved = gitInfo.resolvedUrl(remote.url) else { return [] }
                    guard let apps = try? applicationApi.get(forGit: resolved, with: token) else { return [] }
                    return apps
            }

            if apps.count == 1 {
                let found = apps[0]
                console.info("I found, '\(found.name)',")
                console.info("https://\(found.repo).vapor.cloud")
                let useThis = console.confirm("Would you like to use this app?")
                if useThis { return found.repo }
            } else {
                console.info("I found too many apps, that match remotes in this repo,")
                console.info("yell at Logan to ask me to use one of these.")
                console.info("Instead, I'm going to ask a bunch of questions.")
            }
        }

        let org = try getOrganization(arguments, with: token)
        let proj = try getProject(arguments, in: org, with: token)
        let app = try getApp(arguments, in: proj, with: token)
        return app.repo
    }

    private func inferRepo(with token: Token) -> String? {
        guard gitInfo.isGitProject() else { return nil }
        do {
            let apps = try gitInfo
                .remotes()
                .flatMap { remote -> [Application] in
                    guard let resolved = gitInfo.resolvedUrl(remote.url) else { return [] }
                    guard let apps = try? applicationApi.get(forGit: resolved, with: token) else { return [] }
                    return apps
            }

            if apps.count == 1 {
                return apps[0].repo
            } else {
                console.info("I found too many apps, that match remotes in this repo,")
                console.info("yell at Logan to ask me to use one of these.")
                console.info("Instead, I'm going to ask a bunch of questions.")
                return nil
            }
        } catch { return nil }
    }

    private func getOrganization(_ arguments: [String], with token: Token) throws -> Organization {
        let organizationId = arguments.option("organizationId") ?? localConfig?["organization.id"]?.string
        if let id = organizationId {
            let bar = console.loadingBar(title: "Loading Organization")
            defer { bar.fail() }
            bar.start()
            let org = try adminApi.organizations.get(id: id, with: token)
            bar.finish()
            console.info("Loaded \(org.name)")
            return org
        }

        return try selectOrganization(
            queryTitle: "Which Organization?",
            using: console,
            with: token
        )
    }

    private func getProject(_ arguments: [String], in org: Organization, with token: Token) throws -> Project {
        let projectId = arguments.option("projectId") ?? localConfig?["project.id"]?.string
        if let id = projectId {
            let bar = console.loadingBar(title: "Loading Project")
            defer { bar.fail() }
            bar.start()
            let proj = try adminApi.projects.get(id: id, with: token)
            bar.finish()
            console.info("Loaded \(proj.name)")
            return proj
        }

        return try selectProject(
            in: org,
            queryTitle: "Which Project?",
            using: console,
            with: token
        )
    }

    private func getApp(_ arguments: [String], in proj: Project, with token: Token) throws -> Application {
        let applicationId = arguments.option("applicationId") ?? localConfig?["application.id"]?.string
        if let id = applicationId {
            let bar = console.loadingBar(title: "Loading App")
            defer { bar.fail() }
            bar.start()
            guard let app = try applicationApi.get(for: proj, with: token)
                .lazy
                .filter({ $0.id.uuidString == id })
                .first else { throw "No application found w/ id: \(id). Try cloud setup again" }
            bar.finish()
            console.info("Loaded \(app.name)")
            return app
        }

        return try selectApplication(
            in: proj,
            queryTitle: "Which Application?",
            using: console,
            with: token
        )
    }

    private func getEnvironment(_ arguments: [String], forRepo repo: String, with token: Token) throws -> Environment {
        return try selectEnvironment(
            args: arguments,
            forRepo: repo,
            queryTitle: "Which Environment?",
            using: console,
            with: token
        )
    }

    private func getHosting(forRepo repo: String, with token: Token) throws -> Hosting {
        return try applicationApi.hosting.get(forRepo: repo, with: token)
    }

    private func getReplicas(_ arguments: [String]) -> Int? {
        let existing = arguments.option("replicas")
            ?? localConfig?["replicas"]?.string
        guard let found = existing, let replicas = Int(found), replicas > 0 else { return nil }
        return replicas
    }

    private func getBranch(_ arguments: [String], gitUrl: String, env: Environment) throws -> String {
        if let branch = arguments.option("branch") { return branch }

        var useDefault = arguments.flag("useDefaultBranch")
        if !useDefault {
            useDefault = console.confirm("Use default branch, '\(env.branch)'?")
        }
        guard !useDefault else { return env.branch }

        if let remote = try gitInfo.remote(forUrl: gitUrl) {
            let foundBranches = try gitInfo.remoteBranches(for: remote)
            console.info("I found some branches at '\(gitUrl)',")
            return try console.giveChoice(
                title: "Which one would you like to deploy?",
                in: foundBranches
            ) { $0 }
        }

        return getCustomBranch()
    }

    private func getCustomBranch() -> String {
        return console.ask("What branch would you like to deploy?")
    }

    private func verify(deployBranch: String, remote: String) throws {
        // TODO: Rename isGitDirectory
        guard gitInfo.isGitProject() else { return }

        let local = deployBranch
        let remote = remote + "/" + deployBranch

        let (behind, ahead) = try gitInfo.branchPosition(base: remote, compare: local)
        if behind == 0 && ahead == 0 { return }

        console.print()
        console.warning("Your local branch '\(local)' is not up to date")
        console.warning("with your deploy branch on remote, '\(remote)'.")
        console.print()

        if behind > 0 {
            console.error("\(behind) ", newLine: false)
            console.print("commits behind", newLine: false)
            if ahead > 0 {
                console.print(", and ", newLine: false)
            } else {
                console.print(".")
                console.print()
            }
        }

        if ahead > 0 {
            if behind == 0 {
                console.print("'\(local) is ", newLine: false)
            }
            console.success("\(ahead) ", newLine: false)
            console.print("commits ahead.")
        }
        console.print()

        let goRogue = console.confirm("Are you sure you'd like to continue?", style: .warning)
        guard goRogue else { throw "Push git changes to remote and start again." }
        console.success("Entering override codes ...")
    }
}

func selectOrganization(queryTitle: String, using console: ConsoleProtocol, with token: Token) throws -> Organization {
    let orgsBar = console.loadingBar(title: "Loading Organizations")
    defer { orgsBar.fail() }
    orgsBar.start()
    let organizations = try adminApi.organizations.all(with: token)
    orgsBar.finish()

    return try console.giveChoice(
        title: queryTitle,
        in: organizations
    ) { org in "\(org.name)" }
}

func selectProject(in org: Organization, queryTitle: String, using console: ConsoleProtocol, with token: Token) throws -> Project {
    let projBar = console.loadingBar(title: "Loading Projects")
    defer { projBar.fail() }
    projBar.start()
    let projects = try adminApi.projects.all(with: token).filter { project in
        project.organizationId == org.id
    }
    projBar.finish()

    return try console.giveChoice(
        title: queryTitle,
        in: projects
    ) { proj in return "\(proj.name)" }
}

func selectApplication(
    in proj: Project,
    queryTitle: String,
    using console: ConsoleProtocol,
    with token: Token) throws -> Application {
    let appsBar = console.loadingBar(title: "Loading Applications")
    defer { appsBar.fail() }
    appsBar.start()
    let apps = try applicationApi.get(for: proj, with: token)
    appsBar.finish()

    return try console.giveChoice(
        title: queryTitle,
        in: apps
    ) { app in return "\(app.name) (\(app.repo).vapor.cloud)" }
}

func selectEnvironment(
    args: [String] = [],
    forRepo repo: String,
    queryTitle: String,
    using console: ConsoleProtocol,
    with token: Token) throws-> Environment {

    let envBar = console.loadingBar(title: "Loading Environments")
    let envs = try envBar.perform {
        try applicationApi
            .hosting
            .environments
            .all(forRepo: repo, with: token)
    }
    guard !envs.isEmpty else { throw "No environments found for '\(repo).vapor.cloud'" }

    if let env = args.option("env") {
        guard let loaded = envs.lazy
            .filter({ $0.name == env})
            .first
            else { throw "Environment '\(env)' not found" }
        return loaded
    }
    
    guard !envs.isEmpty else {
        throw "No environments setup, make sure to create an environment for repo \(repo)"
    }
    
    guard envs.count > 1 else { return envs[0] }
    
    return try console.giveChoice(
        title: "Which Environment?",
        in: envs
    ) { env in return "\(env.name)" }
}
