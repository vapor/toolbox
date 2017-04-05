import Console
import Node
import Shared

// TODO: Cache info about current user?
public final class Me: Command {
    public let id = "me"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Shows info about the currently logged in user"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) {
        do {
            let token = try Token.global(with: console)
            let bar = console.loadingBar(title: "Fetching User")
            bar.start()
            do {
                let user = try adminApi.user.get(with: token)
                bar.finish()

                console.success("Name: ", newLine: false)
                console.print("\(user.firstName) \(user.lastName)")
                console.success("Email: ", newLine: false)
                console.print("\(user.email)")

                guard arguments.flag("id") else { return }
                console.success("Id: ", newLine: false)
                console.print("\(user.id.uuidString)")
            } catch {
                bar.fail()
                console.error("Error: \(error)")
                exit(1)
            }
        } catch {
            console.info("No user currently logged in.")
            console.warning("Use 'vapor cloud login' or")
            console.warning("Create an account with 'vapor cloud signup'")
            console.error("Error: \(error)")
        }
    }
}

public final class Refresh: Command {
    public let id = "refresh"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Refreshes vapor token, only while testing, will automate soon."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let bar = console.loadingBar(title: "Refreshing Token")
        bar.start()
        do {
            try adminApi.access.refresh(token)
            try token.saveGlobal()
            bar.finish()
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class Dump: Command {
    public let id = "dump"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Dump info for current user."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let bar = console.loadingBar(title: "Gathering")
        bar.start()
        defer { bar.fail() }

        let organizations = try adminApi.organizations.all(with: token)
        let projects = try adminApi.projects.all(with: token)
        let applications = try projects.flatMap { project in
            try applicationApi.get(for: project, with: token)
        }
        let hosts: [Hosting] = applications.flatMap { app in
            try? applicationApi.hosting.get(forRepo: app.repo, with: token)
        }
        let envs: [Environment] = applications.flatMap { app in
            try? applicationApi.hosting.environments.all(for: app, with: token)
            }
            .flatMap { $0 }

        bar.finish()

        organizations.forEach { org in
            console.success("Organization:")
            console.info("  Name: ", newLine: false)
            console.print(org.name)
            console.info("  Id: ", newLine: false)
            console.print(org.id.uuidString)

            let pros = org.projects(in: projects)
            pros.forEach { pro in
                console.success("  Project:")
                console.info("    Name: ", newLine: false)
                console.print(pro.name)
                console.info("    Color: ", newLine: false)
                console.print(pro.color)
                console.info("    Id: ", newLine: false)
                console.print(pro.id.uuidString)

                let apps = pro.applications(in: applications)
                apps.forEach { app in
                    console.success("    Application:")
                    console.info("      Name: ", newLine: false)
                    console.print(app.name)
                    console.info("      Repo: ", newLine: false)
                    console.print(app.repo)
                    console.info("      Id: ", newLine: false)
                    console.print(app.id.uuidString)

                    guard let host = app.hosting(in: hosts) else { return }
                    console.success("      Hosting: ")
                    console.info("          Git: ", newLine: false)
                    console.print(host.gitUrl)
                    console.info("          Id: ", newLine: false)
                    console.print(host.id.uuidString)

                    let hostEnvs = host.environments(in: envs)
                    hostEnvs.forEach { env in
                        console.success("          Environment:")
                        console.info("            Name: ", newLine: false)
                        console.print(env.name)
                        console.info("            Branch: ", newLine: false)
                        console.print(env.branch)
                        console.info("            Id: ", newLine: false)
                        console.print(env.id.description)
                        console.info("            Running: ", newLine: false)
                        console.print(env.running.description)
                        console.info("            Replicas: ", newLine: false)
                        console.print(env.replicas.description)
                    }
                }
            }
        }


    }
}

extension Organization {
    func projects(in projs: [Project]) -> [Project] {
        return projs.filter { proj in
            proj.organizationId == id
        }
    }
}

extension Project {
    func applications(in apps: [Application]) -> [Application] {
        return apps.filter { app in
            app.projectId == id
        }
    }
}

extension Application {
    func hosting(in hosts: [Hosting]) -> Hosting? {
        return hosts
            .lazy
            .filter { host in
                host.applicationId == self.id
            }
            .first
    }
}

extension Hosting {
    func environments(in envs: [Environment]) -> [Environment] {
        return envs.filter { $0.hostingId == id }
    }
}

extension ConsoleProtocol {
    public func warnGitClean() throws {
        let gitInfo = GitInfo(self)
        guard gitInfo.isGitProject() else { return }
        if try gitInfo.statusIsClean() { return }
        info("You have uncommitted changes!")
        let goRogue = confirm("Are you sure you'd like to continue?", style: .warning)
        guard goRogue else { throw "Commit and try again." }
        print("Rogue mode enabled ...")
    }
}

public final class Create: Command {
    public let id = "create"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Used for creating new things"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        // drop 'create'
        let arguments = arguments.dropFirst().array
        let token = try Token.global(with: console)

        let creatables = [
            (name: "Organization", handler: createOrganization),
            (name: "Project", handler: createProject),
            (name: "Application", handler: createApplication),
            (name: "Environment", handler: createEnvironment),
        ]

        let preLoaded = creatables.lazy
            .filter { id, function in
                for argument in arguments where id.lowercased().hasPrefix(argument) {
                    return true
                }
                return false
            }
            .first

        if let pre = preLoaded {
            try pre.handler(token, arguments)
        } else {
            let choice = try console.giveChoice(
                title: "What would you like to create?",
                in: creatables
            ) { return $0.0 }

            try choice.handler(token, arguments)
        }
    }

    private func createOrganization(with token: Token, args: [String]) throws {
        let name: String
        if let n = args.option("name") {
            name = n
        } else {
            name = console.ask("What would you like to name your new Organization?")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        let new = try creating.perform {
            try adminApi.organizations.create(name: name, with: token)
        }

        console.info("Created: ", newLine: false)
        console.print(new.name)
        console.info("Id: ", newLine: false)
        console.print(new.id.uuidString)
    }

    private func createProject(with token: Token, args: [String]) throws {
        let org: Organization
        if let orgId = args.option("org") {
            org = try adminApi.organizations.get(id: orgId, with: token)
        } else {
            org = try selectOrganization(
                queryTitle: "Which organization would you like to create a Project for?",
                using: console,
                with: token
            )
        }

        let name: String
        if let n = args.option("name") {
            name = n
        } else {
            name = console.ask("What would you like to name your new Project?")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        try creating.perform {
            _ = try adminApi.projects.create(name: name, color: nil, in: org, with: token)
        }
    }

    private func createApplication(with token: Token, args: [String]) throws {
        let proj = try getProject(with: token, args: args)

        let name: String
        if let n = args.option("name") {
            name = n
        } else {
            console.info("What would you like to name your new Application?")
            name = console.ask("(A human readable name)")
        }

        let repo: String
        if let r = args.option("repo") {
            repo = r
        } else {
            console.info("How would you like to identify your new Application?")
            console.info("This needs to be unique, if it doesn't work, it may already be taken.")
            repo = console.ask("(your-answer.vapor.cloud)")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        let new = try creating.perform {
            try applicationApi.create(for: proj, repo: repo, name: name, with: token)
        }

        _ = try setupHosting(for: new, with: token, args: args)

        let environment = console.loadingBar(title: "Creating Production Environment")
        let env = try environment.perform {
             try applicationApi.hosting.environments.create(
                forRepo: new.repo,
                name: "production",
                branch: "master",
                with: token
            )
        }

        let scale = console.loadingBar(title: "Scaling")
        try scale.perform {
            _ = try applicationApi.hosting.environments.setReplicas(
                count: 1,
                forRepo: repo,
                env: env,
                with: token
            )
        }
    }

    private func getProject(with token: Token, args: [String]) throws -> Project {
        if let projId = args.option("proj") {
            return try adminApi.projects.get(id: projId, with: token)
        }

        let org: Organization
        if let orgId = args.option("org") {
            org = try adminApi.organizations.get(id: orgId, with: token)
        } else {
            org = try selectOrganization(
                queryTitle: "Which organization would you like to use?",
                using: console,
                with: token
            )
        }

        return try selectProject(
            in: org,
            queryTitle: "Which Project would you like to use?",
            using: console,
            with: token
        )
    }

    private func setupHosting(for app: Application, with token: Token, args: [String]) throws -> Hosting {
        var remote: String = ""
        if let gitUrl = args.option("gitUrl") {
            remote = gitUrl
        } else {
            do {
                // TODO: Validate SSH Url
                remote = try console.backgroundExecute(
                    program: "git",
                    arguments: ["remote", "get-url", "origin"]
                    ).trim()
            } catch {}

            var useRemote = false
            if !remote.isEmpty {
                console.info("We found '\(remote)'")
                useRemote = console.confirm("Would you like to use this remote to deploy?")
            }
            if !useRemote {
                console.info("What 'git' url should we apply to this hosting?")
                let answer = console.ask(
                    "We require ssh url format currently, ie: git@github.com:vapor/vapor.git"
                )
                guard let resolved = gitInfo.resolvedUrl(answer) else {
                    console.warning("Unable to resolve gitUrl '\(answer)'")
                    throw "Please use ssh formatted git url, ie: git@github.com:vapor/vapor.git"
                }
                remote = resolved
            }
        }

        let hosting = console.loadingBar(title: "Setting up Hosting")
        return try hosting.perform {
            try applicationApi.hosting.create(
                for: app,
                git: remote,
                with: token
            )
        }
    }

    private func createEnvironment(with token: Token, args: [String]) throws {
        let repo = try getCloudRepo(with: token, args: args)

        let name: String
        if let n = args.option("name") {
            name = n
        } else {
            name = console.ask("What would you like to name your new Environment?")
        }

        let branch: String
        if let b = args.option("branch") {
            branch = b
        } else {
            branch = console.ask("(What 'git' branch should we deploy for this Environment?")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        try creating.perform {
            _ = try applicationApi.hosting.environments.create(
                forRepo: repo,
                name: name,
                branch: branch,
                with: token
            )
        }
    }

    private func getCloudRepo(with token: Token, args: [String]) throws -> String {
        if let repo = args.option("repo") {
            return repo
        }

        let project = try getProject(with: token, args: args)
        let app = try selectApplication(
            in: project,
            queryTitle: "Which App?",
            using: console,
            with: token
        )
        return app.repo
    }
}


public final class Add: Command {
    public let id = "add"

    public let signature: [Argument] = []

    public let help: [String] = [
        ""
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let creatables = [
            (name: "Hosting", handler: addHosting),
            ]

        let choice = try console.giveChoice(
            title: "What would you like to add?",
            in: creatables
        ) { return $0.0 }

        try choice.handler(token)
    }

    func addHosting(with token: Token) throws {
        let org = try selectOrganization(
            queryTitle: "Which Organization would you like to add Hosting to?",
            using: console,
            with: token
        )

        let proj = try selectProject(
            in: org,
            queryTitle: "Which Project would you like to add Hosting to?",
            using: console,
            with: token
        )

        let app = try selectApplication(
            in: proj,
            queryTitle: "Which Application would you like to add Hosting to?",
            using: console,
            with: token
        )

        console.info("What 'git' url should we apply to this hosting?")
        let git = console.ask("We require ssh url format currently, ie: git@github.com:vapor/vapor.git")
        let creating = console.loadingBar(title: "Adding Hosting to \(app.name)")
        defer { creating.fail() }
        creating.start()
        _ = try applicationApi.hosting.create(
            for: app,
            git: git,
            with: token
        )
        creating.finish()
    }
}

/*
 Init on vapor project
 */
public final class CloudInit: Command {
    public let id = "init"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Initialize a new cloud project"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        // TODO: Attempt to detect existing configuration file
        console.success("Welcome to Vapor Cloud.")

        if localConfigExists {
            console.warning("Local config file detected, this project")
            console.warning("may already be setup for Vapor Cloud.")
            guard console.confirm("Would you like to continue anyway?", style: .warning) else {
                console.info("Ok, bye.")
                return
            }
        }

        let token = try Token.global(with: console)

        if gitInfo.isGitProject() {
            guard try gitInfo.statusIsClean() else {
                console.info("I'm going to add configuration files,")
                console.info("please make sure you have committed all changes")
                console.info("before continuing.")
                throw "Could not initialize your Cloud."
            }
        }

        let remote = try getGitRemote()
        if gitInfo.isGitProject() {
            let found = try gitInfo.remoteUrls()
            if !found.contains(remote) {
                console.warning("The remote you selected, '\(remote)' is not")
                console.warning("currently in this project's list of git remotes.")
                console.warning("Vapor cloud does NOT detect local changes, and")
                console.warning("will be deploying from this url in the future,")
                console.warning("so please ensure that you have write access,")
                console.warning("and all changes are pushed to '\(remote)'")
                console.warning("before deploying.")
                let override = console.confirm(
                    "Would you like to continue with '\(remote)'?",
                    style: .warning
                )
                guard override else { return }

                let add = console.confirm(
                    "Would you like me to add '\(remote)' to your list of remotes?"
                )
                if add {
                    let existingNames = try gitInfo.remoteNames()
                    if !existingNames.contains("origin") {
                        _ = try console.backgroundExecute(program: "git", arguments: ["remote", "add", "origin", remote])
                        console.info("Added 'origin', after commiting your changes,")
                        console.info("push to this remote before deploying.")
                    } else {
                        let name = console.ask("What would you like to name your remote?")
                        _ = try console.backgroundExecute(program: "git", arguments: ["remote", "add", name, remote])
                        console.info("Added '\(name)', after commiting your changes,")
                        console.info("push to this remote before deploying.")
                    }
                }
            }
        }

        let app = try getApplication(withGit: remote, token: token)
        console.info("Your application \(app.name) is ready to be used.")
        console.info()

        guard projectInfo.isVaporProject() else {
            console.info("Call 'vapor cloud deploy \(app.repo)'")
            console.info("to push your app.")
            let deployNow = console.confirm("Would you like to deploy now?")
            guard deployNow else {
                console.print("Bye for now.")
                return
            }
            let deploy = DeployCloud(console: console)
            try deploy.run(arguments: ["deploy", app.repo])
            return
        }

        console.print("I've detected that you're currently in a Vapor project,")
        console.print("I can add a local cloud configuration file that will")
        console.print("make it easier to deploy new changes.")

        if console.confirm("Would you like to add this now?") {
            let added = try addConfig(for: app)

            if added, gitInfo.isGitProject() {
                let currentBranch = try gitInfo.currentBranch()
                console.print("I've added a config file,")
                console.print("would you like me to commit this change")
                let commitNow = console.confirm("to current branch, '\(currentBranch)'?")
                if commitNow {
                    _ = try console.backgroundExecute(
                        program: "git",
                        arguments: ["add", "."]
                    )
                    _ = try console.backgroundExecute(
                        program: "git",
                        arguments: ["commit", "-m", "added vapor cloud config"]
                    )
                }
            }
        }

        console.info("Call 'vapor cloud deploy' to push your app.")
        let shouldPush = console.confirm("Would you like to deploy now?")
        guard shouldPush else {
            console.print("Bye for now.")
            return
        }

        let deploy = DeployCloud(console: console)
        try deploy.run(arguments: ["deploy"])
    }

    func addConfig(for app: Application) throws -> Bool {
        if localConfigExists {
            console.warning("Existing config will be overwritten,")
            guard console.confirm("would you like to continue?", style: .warning) else {
                return false
            }
        }
        var config = localConfig ?? JSON([:])
        try config.set("updated", Date().timeIntervalSince1970)
        try config.set("project.id", app.projectId)
        try config.set("application.id", app.id)
        try config.set("application.repo", app.repo)
        let file = try config.serialize(prettyPrint: true)
        try DataFile.save(bytes: file, to: localConfigPath)
        return true
    }

    private func getApplication(withGit git: String, token: Token) throws -> Application {
        let bar = console.loadingBar(title: "Loading Applications", animated: true)
        let applications = try bar.perform {
            try applicationApi.get(forGit: git, with: token)
        }

        if !applications.isEmpty {
            console.info("I found the following apps matching '\(git)':")
            applications.forEach { app in
                console.print("- \(app.name) (\(app.repo).vapor.cloud)")
            }
            let useExisting = console.confirm("Would you like to use one of these?")
            if useExisting {
                return try console.giveChoice(
                    title: "Which one?",
                    in: applications
                ) { return "\($0.name) (\($0.repo).vapor.cloud)" }
            }
        }

        console.info("I didn't find an application we could use,")
        // TODO: Give option to update existing application
        let createNew = console.confirm("would you like to create one?")
        guard createNew else {
            console.info("Ok, you can create an application later to get started.")
            throw "No application."
        }

        return try createApplication(gitUrl: git, with: token)
    }


    private func createApplication(gitUrl: String, with token: Token) throws -> Application {
        let org = try getOrganization(with: token)
        let proj = try getProject(for: org, with: token)
        return try createApplication(for: proj, gitUrl: gitUrl, with: token)
    }

    //    private func getApplication(for proj: Project, gitUrl: String, with token: Token) throws -> Application {
    //        let bar = console.loadingBar(title: "Loading Applications", animated: true)
    //        let applications = try bar.perform {
    //            try applicationApi.get(for: proj, with: token)
    //        }
    //
    //        if !applications.isEmpty {
    //            console.info("I found the following apps:")
    //            applications.forEach { app in
    //                console.print("- \(app.name) - \(app.repo).vapor.cloud")
    //            }
    //            let useExisting = console.confirm("Would you like to use one of these?")
    //            if useExisting {
    //                return try console.giveChoice(
    //                    title: "Which one?",
    //                    in: applications
    //                ) { return "\($0.name) - \($0.repo).vapor.cloud" }
    //            }
    //        }
    //
    //        console.info("I didn't find an Application we could use,")
    //        let createNew = console.confirm("would you like to create one?")
    //        guard createNew else {
    //            console.info("Ok, you can create an Application later to get started.")
    //            throw "No application."
    //        }
    //
    //        return try createApplication(for: proj, with: token)
    //    }

    private func createApplication(for proj: Project, gitUrl: String, with token: Token) throws -> Application {
        console.info("What would you like to name your new Application?")
        let name = console.ask("(A human readable name)")

        console.info("How would you like to identify your new Application?")
        console.info("This needs to be unique, if it doesn't work, it may already be taken.")
        let repo = console.ask("(your-answer.vapor.cloud)")

        let creating = console.loadingBar(title: "Creating \(name)")
        let new = try creating.perform {
            return try applicationApi.create(
                for: proj,
                repo: repo,
                name: name,
                with: token
            )
        }

        _ = try setupHosting(for: new, gitUrl: gitUrl, with: token)

        let environment = console.loadingBar(title: "Creating Production Environment")
        let env = try environment.perform {
            return try applicationApi.hosting.environments.create(
                forRepo: new.repo,
                name: "production",
                branch: "master",
                with: token
            )
        }

        let scale = console.loadingBar(title: "Scaling")
        try scale.perform {
            _ = try applicationApi.hosting.environments.setReplicas(count: 1, forRepo: repo, env: env, with: token)
        }

        return new
    }

    private func getOrganization(with token: Token) throws -> Organization {
        let bar = console.loadingBar(title: "Loading Organizations", animated: true)
        let orgs = try bar.perform {
            try adminApi.organizations.all(with: token)
        }

        if !orgs.isEmpty {
            console.info("I found the following Organizations:")
            orgs.forEach { org in
                console.print("- \(org.name)")
            }
            let useExisting = console.confirm("Would you like to use one of these?")
            if useExisting {
                return try console.giveChoice(
                    title: "Which one?",
                    in: orgs
                ) { return "\($0.name)" }
            }
        }

        console.info("I didn't find an organization we could use,")
        let createNew = console.confirm("would you like to create one?")
        guard createNew else {
            console.info("Ok, you can create an Organization later to get started.")
            throw "No organization."
        }

        let name = console.ask("What would you like to name your new Organization?")
        let creating = console.loadingBar(title: "Creating \(name)")
        return try creating.perform {
            try adminApi.organizations.create(name: name, with: token)
        }
    }

    private func getProject(for org: Organization, with token: Token) throws -> Project {
        let bar = console.loadingBar(title: "Loading Projects", animated: true)
        let orgs = try bar.perform {
            try adminApi.projects.all(for: org, with: token)
        }

        if !orgs.isEmpty {
            console.info("I found the following Organizations:")
            orgs.forEach { org in
                console.print("- \(org.name)")
            }
            let useExisting = console.confirm("Would you like to use one of these?")
            if useExisting {
                return try console.giveChoice(
                    title: "Which one?",
                    in: orgs
                ) { return "\($0.name)" }
            }
        }

        console.info("I didn't find a project we could use,")
        let createNew = console.confirm("would you like to create one?")
        guard createNew else {
            console.info("Ok, you can create a Project later to get started.")
            throw "No project."
        }

        let name = console.ask("What would you like to name your new Project?")
        let creating = console.loadingBar(title: "Creating \(name)")
        return try creating.perform {
            try adminApi.projects.create(
                name: name,
                color: nil,
                in: org,
                with: token
            )
        }
    }

    private func setupHosting(for app: Application, gitUrl: String, with token: Token) throws -> Hosting {
        let hosting = console.loadingBar(title: "Setting up Hosting")
        return try hosting.perform {
            try applicationApi.hosting.create(
                for: app,
                git: gitUrl,
                with: token
            )
        }
    }

    private func getGitRemote() throws -> String {
        console.info("To configure your app, I'll need a git remote url")
        console.info("to get started.")
        console.info()
        console.info("This will be used in deploying your application.")
        console.info()

        let remotes = try gitInfo.remotes()

        // Check if we can infer remote
        if let inferred = inferGitRemote(from: remotes) {
            console.info("I found '\(inferred.name)', pointing to '\(inferred.url)';")
            if console.confirm("would you like to use this?") {
                return inferred.url
            }
        }

        // Didn't infer easy remote, check if user wants
        // to select from existing
        if !remotes.isEmpty {
            console.info("I found the following remotes:")
            remotes.forEach { remote in
                console.print("- \(remote.name)")
            }
            if console.confirm("Would you like to use one of these?") {
                let chosen = try console.giveChoice(
                    title: "Ok, which one?",
                    in: remotes
                ) { $0.name }
                guard let resolved = gitInfo.resolvedUrl(chosen.url) else {
                    throw foundBadGitUrl(chosen.url)
                }
                return resolved
            }
        }

        console.info("I didn't find any remotes we could use,")
        console.info("please enter a SSH formatted git remote url.")
        console.info("For example 'git@github.com:vapor/api-template.git'.")
        let remote = console.ask("What remote would you like?")
        guard let resolved = gitInfo.resolvedUrl(remote) else {
            throw foundBadGitUrl(remote)
        }
        return resolved
    }

    private func foundBadGitUrl(_ chosen: String) -> Error {
        console.warning("Unable to use \(chosen).")
        console.info("I am only able to work with SSH urls")
        console.info("at the moment, please format like this")
        console.info("'git@github.com:vapor/api-template.git'")
        return "Unable to resolve \(chosen)."
    }

    private func inferGitRemote(from remotes: [(name: String, url: String)]) -> (name: String, url: String)? {
        guard remotes.count == 1 else { return nil }
        let remote = remotes[0]
        guard let resolved = gitInfo.resolvedUrl(remote.url) else { return nil }
        return (remote.name, resolved)
    }
}


func currentGitBranch(with console: ConsoleProtocol) -> String? {
    let branch = try? console.backgroundExecute(program: "git", arguments: ["branch"])
    return branch?.trim()
}

import Core
import JSON
import Foundation
import Vapor

// TODO: Get home directory
let vaporConfigDir = "\(NSHomeDirectory())/.vapor"
let tokenPath = "\(vaporConfigDir)/token.json"

let localConfigPath = "./.vcloud.json"
var localConfigExists: Bool {
    return FileManager.default.fileExists(atPath: localConfigPath)
}
let localConfigBytes = (try? DataFile.load(path: localConfigPath)) ?? []
var localConfig: JSON? {
    get {
        do {
            guard localConfigExists else { return nil }
            let bytes = try DataFile.load(path: localConfigPath)
            return try JSON(bytes: bytes)
        } catch {
            print("Error loading local config: \(error)")
            return nil
        }
    }
    set {
        do {
            let json = newValue ?? [:]
            let serialized = try json.serialize(prettyPrint: true)
            try DataFile.save(bytes: serialized, to: localConfigPath)
        } catch {
            print("Error updating local config: \(error)")
        }
    }
}

public final class CloudSetup: Command {
    public let id = "setup"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Refreshes vapor token, only while testing, will automate soon."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let name = try projectInfo.packageName()
        guard console.confirm("Would you like to setup a Vapor Cloud configuration for \(name)") else {
            console.info("Ok.")
            return
        }

        let org = try selectOrganization(
            queryTitle: "Select Organization?",
            using: console,
            with: token
        )

        let proj = try selectProject(
            in: org,
            queryTitle: "Select Project?",
            using: console,
            with: token
        )

        let app = try selectApplication(
            in: proj,
            queryTitle: "Select Application?",
            using: console,
            with: token
        )

        var json = JSON([:])
        //        try json.set("organization.id", org.id)
        //        try json.set("project.id", proj.id)
        //        try json.set("application.id", app.id)
        try json.set("app.repoName", app.repo)
        //        try json.set("replicas", replicas)
        let file = try json.serialize(prettyPrint: true)
        try DataFile.save(bytes: file, to: localConfigPath)

        let setup = console.loadingBar(title: "Setup Cloud", animated: false)
        setup.finish()
    }
}




extension Token {
    func saveGlobal() throws {
        try FileManager.default.createVaporConfigFolderIfNecessary()

        var json = JSON([:])
        try json.set("access", access)
        try json.set("refresh", refresh)

        let bytes = try json.serialize()
        try DataFile.save(bytes: bytes, to: tokenPath)
    }

    // TODO: Give opportunity to login/signup right here
    static func global(with console: ConsoleProtocol) throws -> Token {
        let raw = try Node.loadContents(path: tokenPath)
        guard
            let access = raw["access"]?.string,
            let refresh = raw["refresh"]?.string
            else {
                console.info("No user currently logged in.")
                console.warning("Use 'vapor cloud login' or")
                console.warning("Create an account with 'vapor cloud signup'")
                throw "User not found."
        }

        let token = Token(access: access, refresh: refresh)
        token.didUpdate = { t in
            do {
                try t.saveGlobal()
            } catch {
                print("Failed to save updated token: \(error)")
            }
        }
        return token
    }
}

extension Node {
    /**
     Load the file at a path as raw bytes, or as parsed JSON representation
     */
    fileprivate static func loadContents(path: String) throws -> Node {
        let data = try DataFile().load(path: path)
        guard path.hasSuffix(".json") else { return .bytes(data) }
        return try JSON(bytes: data).converted()
    }
}

extension FileManager {
    func createVaporConfigFolderIfNecessary() throws {
        var isDirectory: ObjCBool = false
        fileExists(atPath: vaporConfigDir, isDirectory: &isDirectory)
        guard !isDirectory.boolValue else { return }
        try createDirectory(atPath: vaporConfigDir, withIntermediateDirectories: true)
    }
}

extension ConsoleProtocol {
    func giveChoice<T>(title: String, in array: [T]) throws -> T {
        return try giveChoice(title: title, in: array, display: { "\($0)" })
    }
    
    func giveChoice<T>(title: String, in array: [T], display: (T) -> String) throws -> T {
        info(title)
        array.enumerated().forEach { idx, item in
            let offset = idx + 1
            info("\(offset): ", newLine: false)
            let description = display(item)
            print(description)
        }
        
        output("> ", style: .plain, newLine: false)
        let raw = input()
        guard let idx = Int(raw), (1...array.count).contains(idx) else {
            // .count is implicitly offset, no need to adjust
            throw "Invalid selection: \(raw), expected: 1...\(array.count)"
        }
        
        // undo previous offset back to 0 indexing
        let offset = idx - 1
        return array[offset]
    }
}
