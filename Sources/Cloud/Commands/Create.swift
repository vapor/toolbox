
public final class Create: Command {
    public let id = "create"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Used for creating new things."
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
            repo = console.ask("(your-answer.vapor.cloud)")
        }

        let creating = console.loadingBar(title: "Creating \(name)")
        let new = try creating.perform {
            try applicationApi.create(for: proj, repo: repo, name: name, with: token)
        }

        //print("If user exits after creating, before setting up hosting, needs a way to add hosting/env later")
        //print("ideally, detect no hosting, and create automatically")

        _ = try setupHosting(forRepo: new.repo, with: token, args: args)

        let environment = console.loadingBar(title: "Creating Production Environment")
        let env = try environment.perform {
            try applicationApi.hosting.environments.create(
                forRepo: new.repo,
                name: "production",
                branch: "master",
                with: token
            )
        }

//        let scale = console.loadingBar(title: "Scaling")
//        try scale.perform {
//            _ = try applicationApi.hosting.environments.setReplicas(
//                count: 1,
//                forRepo: repo,
//                env: env,
//                with: token
//            )
//        }

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
        let args = ["deploy", "--app=\(new.repo)", "--env=\(env.name)"]
        try deploy.run(arguments: args)
    }

    private func createHosting(with token: Token, args: [String]) throws {
        let repo = try getRepo(args, console: console, with: token)
        _ = try setupHosting(forRepo: repo, with: token, args: args)
    }

    private func createDatabase(with token: Token, args: [String]) throws {
        let repo = try getRepo(args, console: console, with: token)
        let env = try getEnv(forRepo: repo, args: args, with: token)
        try applicationApi.hosting.environments.database.create(
            forRepo: repo,
            envName: env,
            with: token
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
            branch = console.ask("What 'git' branch should we deploy for this Environment?")
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
        return app.repo
    }
}
