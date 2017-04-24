public final class Create: Command {
    public let id = "create"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Used for creating new things."
    ]

    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory

    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
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
            (name: "Hosting", handler: createHosting),
            (name: "Database", handler: createDatabase),
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
        if let id = new.id?.string {
            console.info("Id: ", newLine: false)
            console.print(id)
        }
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
            repo = console.ask("(your-answer.vapor.cloud)")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        let new = try creating.perform {
            try applicationApi.create(for: proj, repo: repo, name: name, with: token)
        }

        //print("If user exits after creating, before setting up hosting, needs a way to add hosting/env later")
        //print("ideally, detect no hosting, and create automatically")

        _ = try setupHosting(forRepo: new.repoName, with: token, args: args)

        let replicaSize = try ReplicaSize(node: args.option("replicaSize"))
        let env = try makeEnvironment(
            repo: repo,
            name: "production",
            branch: "master",
            replicaSize: replicaSize
        )

        // Temporarily setting up database by default
        try applicationApi.hosting.environments.database.create(
            forRepo: repo,
            envName: env.name,
            with: token
        )

        console.info("Your application is now ready.")
        let deployNow = console.confirm("Would you like to deploy \(new.name) now?")
        guard deployNow else { return }
        let deploy = DeployCloud(console: console)
        let args = ["deploy", "--app=\(new.repoName)", "--env=\(env.name)"]
        try deploy.run(arguments: args)
    }

    private func askReplicaSize() throws -> ReplicaSize {
        return try console.giveChoice(title: "What Replica Size?", in: ReplicaSize.all) { $0.string }
    }

    private func createHosting(with token: Token, args: [String]) throws {
        let repo = try getRepo(args, console: console, with: token)
        _ = try setupHosting(forRepo: repo, with: token, args: args)
    }

    private func createDatabase(with token: Token, args: [String]) throws {
        let repo = try getRepo(args, console: console, with: token)
        let env = try getEnv(forRepo: repo, args: args, with: token)
        let repoName = Identifier(repo)
        let envName = Identifier(env)
        _ = try makeDatabase(
            environment: .identifier(envName),
            application: .identifier(repoName)
        )
    }

    private func getEnv(forRepo repo: String, args: [String], with token: Token) throws -> String {
        let env: String
        if let name = args.option("env") {
            env = name
        } else {
            let e = try selectEnvironment(
                args: args,
                forRepo: repo,
                queryTitle: "Which Environment?",
                using: console,
                with: token
            )

            env = e.name
        }
        return env
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

    private func setupHosting(forRepo repo: String, with token: Token, args: [String]) throws -> Hosting {
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
                forRepo: repo,
                git: remote,
                with: token
            )
        }
    }

    private func createEnvironment(with token: Token, args: [String]) throws {
        let repo = try getCloudRepo(with: token, args: args)
        console.detail("app", repo)
        
        let name: String
        if let n = args.option("name") {
            name = n
        } else {
            console.print("Environment names correspond to:")
            console.print("- Subfolders of Config, e.g., Config/staging/*.json")
            console.print("- Hosted URLs, e.g., http://myproject-staging.vapor.cloud")
            console.print("Good environment names resemble git branch names,")
            console.print("i.e., develop, staging, production, testing.")
            name = console.ask("What name for this environment?")
            console.clear(lines: 7)
        }
        console.detail("environment", name)
        
        let branch: String
        if let b = args.option("branch") {
            branch = b
        } else {
            branch = console.ask("What 'git' branch should we deploy for this Environment?")
            console.clear(lines: 2)
        }
        console.detail("default branch", branch)
        
        let replicaSize: ReplicaSize
        if let size = args.option("replicaSize") {
            replicaSize = try ReplicaSize(node: size)
        } else {
            replicaSize = try console.giveChoice(title: "What size replica(s)?", in: ReplicaSize.all)
        }
        console.detail("replica size", "\(replicaSize)")
        
        guard console.confirm("Is the above information correct?") else {
            throw "Cancelled"
        }
        
        _ = try makeEnvironment(
            repo: repo,
            name: name,
            branch: branch,
            replicaSize: replicaSize
        )
    }

    private func makeEnvironment(
        repo: String,
        name: String,
        branch: String,
        replicaSize: ReplicaSize
    ) throws -> Environment {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        
        let repoName = Identifier(repo)
        let env: Environment = try console.loadingBar(title: "Creating \(name) environment") {
            let env = Environment(
                id: nil,
                hosting: .identifier(""),
                name: name,
                replicas: 0,
                replicaSize: replicaSize,
                defaultBranch: branch
            )
            
            return try cloud.create(env, for: .identifier(repoName))
        }
        let envName = Identifier(env.name)
        
        if console.confirm("Add a database?") {
            _ = try makeDatabase(
                environment: .identifier(envName),
                application: .identifier(repoName)
            )
        }
        
        return env
    }
    
    private func makeDatabase(
        environment: ModelOrIdentifier<Environment>,
        application: ModelOrIdentifier<Application>
    ) throws -> Database {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let servers = try cloud.databaseServers()
        let server = try console.giveChoice(
            title: "Which database server?",
            in: servers
        ) { server in
            return "\(server.name) (\(server.kind))"
        }
        console.detail("database server", server.name)
        
        let database = try Database(
            id: nil,
            databaseServer: .model(server),
            environment: environment
        )
        
        return try console.loadingBar(title: "Creating database") {
            return try cloud.create(
                database,
                for: application,
                in: environment
            )
        }
    }

    private func getCloudRepo(with token: Token, args: [String]) throws -> String {
        if let repo = args.option("app") {
            return repo
        }

        let project = try getProject(with: token, args: args)
        let app = try selectApplication(
            in: project,
            queryTitle: "Which App?",
            using: console,
            with: token
        )
        return app.repoName
    }
}

extension ReplicaSize {
    static let all: [ReplicaSize] = {
        switch ReplicaSize.free {
        case .free:
            break
        case .small:
            break
        case .medium:
            break
        case .large:
            break
        case .xlarge:
            break
        }

        return [
            .free,
            .small,
            .medium,
            .large,
            .xlarge
        ]
    }()
}
