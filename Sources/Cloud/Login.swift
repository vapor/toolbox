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
        "Gather metadata of cloud from local where possible"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        /////
        let org = try selectOrganization(
            queryTitle: "Which Organization?",
            using: console,
            with: token
        )
        /////

        let proj = try selectProject(
            in: org,
            queryTitle: "Which Project?",
            using: console,
            with: token
        )

        /////

        let app = try selectApplication(
            in: proj,
            queryTitle: "Which Application?",
            using: console,
            with: token
        )

        /////

        let envBar = console.loadingBar(title: "Loading Environments")
        defer { envBar.fail() }
        envBar.start()
        let envs = try applicationApi.hosting.environments.all(for: app, with: token)
        envBar.finish()

        let env = try console.giveChoice(
            title: "Which Environment?",
            in: envs
        ) { env in return "\(env.name)" }

        /////

        let answer = console.ask("How many replicas?")
        guard let replicas = Int(answer), replicas > 0 else {
            throw "Expected a number greater than 1, got \(answer)."
        }

        let deployBar = console.loadingBar(title: "Deploying")
        defer { deployBar.fail() }
        deployBar.start()
        let deploy = try applicationApi.deploy.deploy(
            for: app,
            replicas: replicas,
            env: env,
            code: .incremental,
            with: token
        )
        deployBar.finish()

        // No output for scale apis
        if let _ = deploy.deployments.lazy.filter({ $0.type == .scale }).first {
            let scaleBar = console.loadingBar(title: "Scaling", animated: false)
            scaleBar.finish()
        }

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
    for app: Application,
    queryTitle: String,
    using console: ConsoleProtocol,
    with token: Token) throws-> Environment {
    let envBar = console.loadingBar(title: "Loading Environments")
    defer { envBar.fail() }
    envBar.start()
    let envs = try applicationApi.hosting.environments.all(for: app, with: token)
    envBar.finish()

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
            (name: "Hosting", handler: createHosting),
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
            queryTitle: "Which organization would you like to create a project for?",
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
        _ = try applicationApi.create(for: proj, repo: repo, name: name, with: token)
        creating.finish()
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
        _ = try applicationApi.hosting.environments.create(
            for: app,
            name: name,
            branch: branch,
            with: token
        )
        creating.finish()
    }

    func createHosting(with token: Token) throws {
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
