import Console
import Node

public func group(_ console: ConsoleProtocol) -> Group {
    return Group(
        id: "cloud",
        commands: [
            Login(console: console),
            Logout(console: console),
            Signup(console: console),
            Me(console: console),
            Refresh(console: console),
            TokenCommand(console: console),
            Organizations(console: console),
            Projects(console: console),
            Applications(console: console),
            DeployCloud(console: console),
            Dump(console: console),
            DeployCloud(console: console),
            Create(console: console),
            Add(console: console),
            CloudSetup(console: console),
        ],
        help: [
            "Commands for interacting with Vapor Cloud."
        ]
    )
}

public final class Login: Command {
    public let id = "login"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you into Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let email = arguments.option("email") ?? console.ask("Email: ")
        let pass = arguments.option("pass") ?? console.ask("Password: ")

        let loginBar = console.loadingBar(title: "Logging in", animated: !arguments.flag("verbose"))
        loginBar.start()
        do {
            let token = try adminApi.login(email: email, pass: pass)
            try token.saveGlobal()
            loginBar.finish()
            console.success("Welcome back.")
        } catch {
            console.warning("Failed to login user")
            console.warning("User 'vapor cloud signup' if you don't have an account")
            loginBar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class Logout: Command {
    public let id = "logout"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you out of Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let bar = console.loadingBar(title: "Logging out")
        bar.start()
        do {
            if FileManager.default.fileExists(atPath: tokenPath) {
                _ = try DataFile.delete(at: tokenPath)
            }
            bar.finish()
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class TokenCommand: Command {
    public let id = "token"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Cached token metadata for debugging."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let limit = 25
        let token = try Token.global(with: console)
        let access: String
        if arguments.flag("full") {
            access = token.access
        } else {
            access = token.access
                .makeBytes()
                .prefix(limit)
                .makeString()
                + "..."
        }

        console.info("Access: ", newLine: false)
        console.print(access)

        let refresh: String
        if arguments.flag("full") {
            refresh = token.refresh
        } else {
            refresh = token.refresh
                .makeBytes()
                .prefix(limit)
                .makeString() + "..."
        }
        console.info("Refresh: ", newLine: false)
        console.print(refresh)

        console.info("Expiration: ", newLine: false)
        let expiration = token.expiration.timeIntervalSince1970 - Date().timeIntervalSince1970
        if expiration >= 0 {
            console.success("\(expiration) seconds from now.")
        } else {
            console.warning("\(expiration * -1) seconds ago.")
        }
    }
}

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
        "Dump info."
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
        let applications = try projects.flatMap { project in try applicationApi.get(for: project, with: token) }
        let hosts = applications.flatMap { app in
            try? applicationApi.hosting.get(for: app, with: token)
        }

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
        // drop 'deploy' from argument list
        let arguments = arguments.dropFirst().array
        let token = try Token.global(with: console)


        let repo = try getRepo(arguments, with: token)
        let env = try getEnvironment(arguments, forRepo: repo, with: token)
        let replicas = getReplicas(arguments)

        /// Deploy
        let deployBar = console.loadingBar(title: "Deploying")
        defer { deployBar.fail() }
        deployBar.start()
        let deploy = try applicationApi.deploy.deploy(
            for: repo,
            replicas: replicas,
            env: env.name,
            code: .incremental,
            with: token
        )
        deployBar.finish()

        /// No output for scale apis
        if let _ = deploy.deployments.lazy.filter({ $0.type == .scale }).first {
            let scaleBar = console.loadingBar(title: "Scaling", animated: false)
            scaleBar.finish()
        }

        /// Build Logs
        guard let code = deploy.deployments.lazy.filter({ $0.type == .code }).first else { return }
        console.info("Connecting to build logs ...")
        var logsBar: LoadingBar?
        try Redis.subscribeDeployLog(id: code.id.uuidString) { update in
            if update.type == .start {
                logsBar = self.console.loadingBar(title: update.message)
                logsBar?.start()
            } else if update.success {
                logsBar?.finish()
            } else {
                logsBar?.fail()
            }
            
        }

        console.success("Successfully deployed.")
        console.info("Deployed: \n\(deploy)")
    }

    private func getRepo(_ arguments: [String], with token: Token) throws -> String {
        if let repo = arguments.values.first ?? localConfig?["application.repo"]?.string {
            return repo
        }

        let org = try getOrganization(arguments, with: token)
        let proj = try getProject(arguments, in: org, with: token)
        let app = try getApp(arguments, in: proj, with: token)
        return app.repo
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
        if let env = arguments.option("env") {
            let envBar = console.loadingBar(title: "Loading Environments")
            defer { envBar.fail() }
            envBar.start()
            guard let loaded = try applicationApi
                .environments
                .all(forRepo: repo, with: token)
                .lazy
                .filter({ $0.name == env})
                .first
                else { throw "Environment '\(env)' not found" }
            envBar.finish()
            console.info("Loaded \(loaded.name)")
            return loaded
        }

        return try selectEnvironment(
            forRepo: repo,
            queryTitle: "Which Environment?",
            using: console,
            with: token
        )
    }

    private func getReplicas(_ arguments: [String]) -> Int? {
        let existing = arguments.option("replicas")
            ?? localConfig?["replicas"]?.string
        guard let found = existing, let replicas = Int(found), replicas > 0 else { return nil }
        return replicas
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
    ) { org in "\(org.name) - \(org.id)" }
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
    ) { proj in return "\(proj.name) - \(proj.id)" }
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
    ) { app in return "\(app.name) - \(app.repo) - \(app.id)" }
}

func selectEnvironment(
    forRepo repo: String,
    queryTitle: String,
    using console: ConsoleProtocol,
    with token: Token) throws-> Environment {
    let envBar = console.loadingBar(title: "Loading Environments")
    defer { envBar.fail() }
    envBar.start()
    let envs = try applicationApi.environments.all(forRepo: repo, with: token)
    envBar.finish()

    guard !envs.isEmpty else {
        throw "No environments setup, make sure to create an environment for repo \(repo)"
    }

    return try console.giveChoice(
        title: "Which Environment?",
        in: envs
    ) { env in return "\(env.name)" }
}

public final class Create: Command {
    public let id = "create"

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

        let creatables = [
            (name: "Organization", handler: createOrganization),
            (name: "Project", handler: createProject),
            (name: "Application", handler: createApplication),
            (name: "Environment", handler: createEnvironment),
        ]

        let choice = try console.giveChoice(
            title: "What would you like to create?",
            in: creatables
        ) { return $0.0 }

        try choice.handler(token)
    }

    private func createOrganization(with token: Token) throws {
        let name = console.ask("What would you like to name your new Organization?")
        let creating = console.loadingBar(title: "Creating \(name)")
        defer { creating.fail() }
        creating.start()
        let new = try adminApi.organizations.create(name: name, with: token)
        creating.finish()
        console.info("\(new.name) - \(new.id)")
    }

    private func createProject(with token: Token) throws {
        let org = try selectOrganization(
            queryTitle: "Which organization would you like to create a Project for?",
            using: console,
            with: token
        )

        let name = console.ask("What would you like to name your new Project?")
        let creating = console.loadingBar(title: "Creating \(name)")
        defer { creating.fail() }
        creating.start()
        _ = try adminApi.projects.create(name: name, color: nil, in: org, with: token)
        creating.finish()
    }

    private func createApplication(with token: Token) throws {
        let org = try selectOrganization(
            queryTitle: "Which Organization would you like to create an Application for?",
            using: console,
            with: token
        )

        let proj = try selectProject(
            in: org,
            queryTitle: "Which Project would you like to create an Application for?",
            using: console,
            with: token
        )

        console.info("What would you like to name your new Application?")
        let name = console.ask("(A human readable name)")

        console.info("How would you like to identify your new Application?")
        console.info("This needs to be unique, if it doesn't work, it may already be taken.")
        let repo = console.ask("(your-answer.vapor.cloud)")

        let creating = console.loadingBar(title: "Creating \(name)")
        defer { creating.fail() }
        creating.start()
        let new = try applicationApi.create(for: proj, repo: repo, name: name, with: token)
        creating.finish()

        _ = try setupHosting(for: new, with: token)

        let environment = console.loadingBar(title: "Creating Production Environment")
        defer { environment.fail() }
        environment.start()
        let env = try applicationApi.environments.create(for: new, name: "production", branch: "master", with: token)
        environment.finish()

        let scale = console.loadingBar(title: "Scaling")
        defer { scale.fail() }
        scale.start()
        try applicationApi.environments.update(forRepo: repo, env, replicas: 1, with: token)
        scale.finish()
    }

    private func setupHosting(for app: Application, with token: Token) throws -> Hosting {
        var remote = ""
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
            useRemote = console.confirm("Would you like to deploy from this remote?")
        }
        if !useRemote {
            console.info("What 'git' url should we apply to this hosting?")
            remote = console.ask("We require ssh url format currently, ie: git@github.com:vapor/vapor.git")
        }

        let hosting = console.loadingBar(title: "Setting up Hosting")
        defer { hosting.fail() }
        hosting.start()
        let new = try applicationApi.hosting.create(for: app, git: remote, with: token)
        hosting.finish()

        return new
    }

    private func createEnvironment(with token: Token) throws {
        let org = try selectOrganization(
            queryTitle: "Which Organization would you like to create an Environment for?",
            using: console,
            with: token
        )

        let proj = try selectProject(
            in: org,
            queryTitle: "Which Project would you like to create an Environment for?",
            using: console,
            with: token
        )

        let app = try selectApplication(
            in: proj,
            queryTitle: "Which Application would you like to create an Environment for?",
            using: console,
            with: token
        )

        let name = console.ask("What would you like to name your new Environment?")
        let branch = console.ask("(What 'git' branch should we deploy for this Environment?")
        let creating = console.loadingBar(title: "Creating \(name)")
        defer { creating.fail() }
        creating.start()
        _ = try applicationApi.environments.create(
            for: app,
            name: name,
            branch: branch,
            with: token
        )
        creating.finish()
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

// TODO: Paging
public final class Organizations: Command {
    public let id = "organizations"

    public let signature: [Argument] = []

    public let help: [String] = [
        // Should be a group
        "Logs all organizations"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let arguments = arguments.dropFirst().values
        guard !arguments.isEmpty || arguments.first == "list" else {
            print("listing")
            try list(with: token)
            exit(0)
        }

        let command = arguments[0]
        if command == "create" {
            guard arguments.count > 1 else { throw "Invalid signature" }
            let name = arguments[1]
            let bar = console.loadingBar(title: "Creating \(name) Organization")
            do {
                let organization = try adminApi.organizations.create(name: name, with: token)
                bar.finish()
                console.info("\(organization.name): ", newLine: false)
                console.print("\(organization.id)")
            } catch {
                bar.fail()
                console.error("Error: \(error)")
            }
        }
    }

    private func list(with token: Token) throws {
        let bar = console.loadingBar(title: "Fetching Organizations")
        bar.start()
        do {
            let organizations = try adminApi.organizations.all(with: token)
            bar.finish()

            organizations.forEach { organization in
                console.info("- \(organization.name): ", newLine: false)
                console.print("\(organization.id)")
            }
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }

    }
}

func currentGitBranch(with console: ConsoleProtocol) -> String? {
    let branch = try? console.backgroundExecute(program: "git", arguments: ["branch"])
    return branch?.trim()
}

public final class Projects: Command {
    public let id = "projects"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Interact w/ your vapor projects"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        try list(with: token)
    }

    private func list(with token: Token) throws {
        print("Combine projects/organizations/applications into list ... keep dump")
        let bar = console.loadingBar(title: "Fetching Projects")
        bar.start()
        do {
            let projects = try adminApi.projects.all(with: token)

            var organizationGroup = [UUID: [Project]]()
            projects.forEach { proj in
                var array = organizationGroup[proj.organizationId] ?? []
                array.append(proj)
                organizationGroup[proj.organizationId] = array
            }
            bar.finish()

            organizationGroup.forEach { org, projects in
                console.success("Org: \(org)")
                projects.forEach { proj in
                    console.info("- \(proj.name): ", newLine: false)
                    console.print("\(proj.id)")
                }
            }
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class Applications: Command {
    public let id = "applications"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs applications."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let projects = try adminApi.projects.all(with: token)
        let project = try console.giveChoice(title: "Choose Project", in: projects)
        let applications = try applicationApi.get(for: project, with: token)
        applications.forEach { app in
            console.info("\(app)")
        }
    }
}

public final class Signup: Command {
    public let id = "signup"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Creates a new Vapor Cloud user."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let email = console.ask("Email: ")
        let pass = console.ask("Password: ")
        let firstName = console.ask("First Name: ")
        let lastName = console.ask("Last Name: ")
        let organization = "My Cloud"

        let bar = console.loadingBar(title: "Creating User")
        bar.start()
        do {
            try adminApi.create(
                email: email,
                pass: pass,
                firstName: firstName,
                lastName: lastName,
                organizationName: organization,
                image: nil
            )
            bar.finish()
            console.success("Welcome to Vapor Cloud.")
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }

        guard console.confirm("Would you like to login now?") else { return }
        let login = Login(console: console)

        var arguments = arguments
        arguments.append("--email=\(email)")
        arguments.append("--pass=\(pass)")
        try login.run(arguments: arguments)
    }
}

import Core
import JSON
import Foundation
import Vapor

// TODO: Get home directory
let vaporConfigDir = "\(NSHomeDirectory())/.vapor"
let tokenPath = "\(vaporConfigDir)/token.json"

let localConfigPath = "./.vcloud.json"
let localConfigBytes = (try? DataFile.load(path: localConfigPath)) ?? []
let localConfig = try? JSON(bytes: localConfigBytes)

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

        let name = try CurrentProject(console).packageName()
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

        let replicasAnswer = console.ask("How many replicas for this application?")
        guard let replicas = Int(replicasAnswer), replicas > 0 else {
            throw "Expected a number greater than 1, got \(replicasAnswer)."
        }

        var json = JSON([:])
        try json.set("organization.id", org.id)
        try json.set("project.id", proj.id)
        try json.set("application.id", app.id)
        try json.set("replicas", replicas)
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
        try json.set("expiration", expiration.timeIntervalSince1970)

        let bytes = try json.serialize()
        try DataFile.save(bytes: bytes, to: tokenPath)
    }

    static func global(with console: ConsoleProtocol) throws -> Token {
        let raw = try Node.loadContents(path: tokenPath)
        guard
            let access = raw["access"]?.string,
            let refresh = raw["refresh"]?.string,
            let timestamp = raw["expiration"]?.double
            else {
                console.info("No user currently logged in.")
                console.warning("Use 'vapor cloud login' or")
                console.warning("Create an account with 'vapor cloud signup'")
                exit(1)
            }

        let expiration = Date(timeIntervalSince1970: timestamp)
        let token = Token(access: access, refresh: refresh, expiration: expiration)
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

//// THIS IS COPY PASTA CLEAN UP LATER
public final class CurrentProject {
    public let console: ConsoleProtocol

    public init(_ console: ConsoleProtocol) {
        self.console = console
    }

    /// Access project metadata through 'swift package dump-package'
    public func package() throws -> JSON? {
        let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
        return try? JSON(bytes: dump.makeBytes())
    }

    public func isSwiftProject() -> Bool {
        do {
            let result = try console.backgroundExecute(program: "ls", arguments: ["./Package.swift"])
            return result.trim() == "./Package.swift"
        } catch {
            return false
        }
    }

    public func isVaporProject() throws -> Bool {
        return try dependencyURLs().contains("https://github.com/vapor/vapor.git")
    }

    /// Get the name of the current Project
    public func packageName() throws -> String {
        guard let name = try package()?["name"]?.string else {
            throw "Unable to determine package name."
        }
        return name
    }

    /// Dependency URLs of current Project
    public func dependencyURLs() throws -> [String] {
        let dependencies = try package()?["dependencies.url"]?
            .array?
            .flatMap { $0.string }
            ?? []
        return dependencies
    }

    public func checkouts() throws -> [String] {
        return try FileManager.default
            .contentsOfDirectory(atPath: "./.build/checkouts/")
    }

    public func vaporCheckout() throws -> String? {
        return try checkouts()
            .lazy
            .filter { $0.hasPrefix("vapor.git") }
            .first
    }

    public func vaporVersion() throws -> String {
        guard let checkout = try vaporCheckout() else {
            throw "Unable to locate vapor dependency"
        }

        let gitDir = "--git-dir=./.build/checkouts/\(checkout)/.git"
        let workTree = "--work-tree=./.build/checkouts/\(checkout)"
        let version = try console.backgroundExecute(
            program: "git",
            arguments: [
                gitDir,
                workTree,
                "describe",
                "--exact-match",
                "--tags",
                "HEAD"
            ]
        )
        return version.trim()
    }

    public func availableExecutables() throws -> [String] {
        let executables = try console.backgroundExecute(
            program: "find",
            arguments: ["./Sources", "-type", "f", "-name", "main.swift"]
        )
        let names = executables.components(separatedBy: "\n")
            .flatMap { path in
                return path.components(separatedBy: "/")
                    .dropLast() // drop main.swift
                    .last // get name of source folder
        }

        // For the use case where there's one package
        // and user hasn't setup lower level paths
        return try names.map { name in
            if name == "Sources" {
                return try packageName()
            }
            return name
        }
    }

    public func buildFolderExists() -> Bool {
        do {
            let ls = try console.backgroundExecute(program: "ls", arguments: ["-a", "."])
            return ls.contains(".build")
        } catch { return false }
    }
}
