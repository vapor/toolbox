import Shared

public final class DeployCloud: Command {
    public let id = "deploy"

    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
        ]),
        Option(name: "env", help: [
            "The name of the environment to deploy to.",
            "This will always be required to deploy, however",
            "omitting the flag will result in a selection menu."
        ]),
        Option(name: "branch", help: [
            "The name of the Git branch to deploy from.",
            "If not passed, the environment's default branch",
            "will be used"
        ]),
        Option(name: "build", help: [
            "The type of build to perform.",
            "Options include: incremental, update, clean",
            "This will always be required to deploy, however",
            "omitting the flag will result in a selection menu."
        ]),
        Option(name: "replicas", help: [
            "The number of replicas to deploy.",
            "Note: Increasing the number of replicas will",
            "result in increased hourly cost based on the environment's",
            "replica size."
        ])
    ]

    public let help: [String] = [
        "Deploy a project to Vapor Cloud"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }

    public func run(arguments: [String]) throws {
        try console.warnGitClean()
        
        // get deploy details
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try cloud.application(for: arguments, using: console)
        let env = try cloud.environment(on: .model(app), for: arguments, using: console)
        let hosting = try cloud.hosting(on: .model(app), for: arguments, using: console)
        let replicas = self.replicas(for: arguments, in: env)
        let replicaSize = try self.replicaSize(for: arguments, in: env)
        let branch = self.branch(for: arguments, in: env)
        let buildType = try self.buildType(for: arguments)
        
        try console.verifyAboveCorrect()
        
        // verify git
        if gitInfo.isGitProject(), let matchingRemote = try gitInfo.remote(forUrl: hosting.gitURL) {
            // verify there's not uncommitted changes
            try gitInfo.verify(local: branch, remote: matchingRemote)
        }


        // deploy
        let (environment, deployment) = try console.loadingBar(title: "Creating deployment") {
            return try cloud.deploy(
                environment: .model(env),
                application: .model(app),
                gitBranch: branch,
                replicas: replicas,
                replicaSize: replicaSize,
                method: Deployment.Method.code(buildType)
            )
        }

        console.info("Connecting to build logs ...")
        var waitingInQueue = console.loadingBar(title: "Waiting in Queue")
        defer { waitingInQueue.fail() }
        waitingInQueue.start()

        guard let id = try deployment.assertIdentifier().string else {
            throw "Invalid deployment identifier"
        }
        
        var logsBar: LoadingBar?
        try Redis.subscribeDeployLog(id: id) { update in
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

    private func buildType(for arguments: [String]) throws -> BuildType {
        let buildType: BuildType
        if let option = arguments.option("build") {
            guard let chosen = BuildType(rawValue: option) else {
                console.warning("Unrecognized build type \(option)")
                let buildTypes = BuildType.all.map { $0.rawValue }.joined(separator: ", ")
                console.detail("Build types", buildTypes)
                throw "Invalid build type"
            }

            buildType = chosen
        } else {
            buildType = try console.giveChoice(
                title: "Which build type?",
                in: BuildType.all
            )
        }
        console.detail("build", "\(buildType)")
        return buildType
    }
    
    private func replicaSize(for arguments: [String], in env: Environment) throws -> ReplicaSize {
        let replicaSize: ReplicaSize
        if let chosen = arguments.option("replicaSize")?.string {
            replicaSize = try ReplicaSize(node: chosen)
        } else {
            replicaSize = env.replicaSize
        }
        console.detail("replica size", replicaSize.string)
        return replicaSize
    }
    
    private func replicas(for arguments: [String], in env: Environment) -> Int {
        let replicas: Int
        if let chosen = arguments.option("replicas")?.int {
            replicas = chosen
        } else {
            replicas = env.replicas
        }
        console.detail("replicas", replicas.description)
        return replicas
    }

    private func branch(for arguments: [String], in env: Environment) -> String {
        let branch: String
        if let chosen = arguments.option("branch") {
            branch = chosen
        } else {
            branch = env.defaultBranch
        }
        console.detail("branch", branch)
        return branch
    }
}

extension GitInfo {
    public func verify(local localBranch: String, remote: String, upstream: String? = nil) throws {
        guard isGitProject() else { return }

        let local = localBranch
        let upstream = upstream ?? localBranch
        let remote = remote + "/" + upstream

        let (behind, ahead) = try branchPosition(base: remote, compare: local)
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
                console.print("\(local) is ", newLine: false)
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
