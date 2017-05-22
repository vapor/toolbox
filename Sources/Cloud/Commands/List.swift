public final class List: Command {
    public let id = "list"

    public let signature: [Argument] = []

    public let help: [String] = [
        "List various owned items of user"
    ]

    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory

    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let arguments = arguments.dropFirst().array // drop 'list'
        let showIds = arguments.flag("id")

        let options = [
            (id: "Organizations", runner: listOrganizations),
            (id: "Projects", runner: listProjects),
            (id: "Applications", runner: listApplications),
            (id: "Domains", runner: listDomains),
        ]

        let preLoaded = options.lazy
            .filter { id, function in
                for argument in arguments where id.lowercased().hasPrefix(argument) {
                    return true
                }
                return false
            }
            .first
        if let preLoaded = preLoaded {
            try preLoaded.runner(token, showIds)
        } else {
            let choice = try console.giveChoice(
                title: "What would you like to list?",
                in: options
            ) { "\($0.id)" }
            try choice.runner(token, showIds)
        }
    }

    func listOrganizations(with token: Token, showIds: Bool) throws {
        let bar = console.loadingBar(title: "Fetching Organizations")
        let orgs = try bar.perform {
            try adminApi.organizations.all(with: token)
        }

        orgs.forEach { console.log($0) }
    }

    func listProjects(with token: Token, showIds: Bool) throws {
        let bar = console.loadingBar(title: "Fetching Projects")
        let projs = try bar.perform {
            try adminApi.projects.all(with: token)
        }

        projs.forEach { console.log($0) }
    }

    func listApplications(with token: Token, showIds: Bool) throws {
        let bar = console.loadingBar(title: "Fetching Apps")
        let apps = try bar.perform {
            try applicationApi.all(with: token)
        }

        apps.forEach { console.log($0) }
    }
    
    func listDomains(with token: Token, showIds: Bool) throws {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try console.application(for: CommandLine.arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: CommandLine.arguments, using: cloudFactory)
        let domains = try console.loadingBar(title: "Loading domains") {
            return try cloud.domains(
                for: .model(env),
                on: .model(app)
            )
        }
        
        console.print("Domains:")
        domains.forEach { domain in
            console.info(domain.domain + domain.path)
        }
    }
}
