public final class List: Command {
    public let id = "list"

    public let signature: [Argument] = []

    public let help: [String] = [
        "List various owned items of user"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let arguments = arguments.dropFirst().array // drop 'list'
        let showIds = arguments.flag("id")

        let options = [
            (id: "Organizations", runner: listOrganizations),
            (id: "Projects", runner: listProjects),
            (id: "Applications", runner: listApplications),
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

        orgs.forEach { org in
            console.info("- \(org.name)", newLine: !showIds)
            if showIds {
                let uuid = try? org.uuid().uuidString
                let id = uuid ?? "<no-id>"
                console.print(": \(id)")
            }
        }
    }

    func listProjects(with token: Token, showIds: Bool) throws {
        let bar = console.loadingBar(title: "Fetching Projects")
        let projs = try bar.perform {
            try adminApi.projects.all(with: token)
        }

        projs.forEach { proj in
            console.info("- \(proj.name)", newLine: !showIds)
            if showIds {
                let id = proj.id?.string ?? "<no-id>"
                console.print(": \(id)")
            }
        }
    }

    func listApplications(with token: Token, showIds: Bool) throws {
        let bar = console.loadingBar(title: "Fetching Apps")
        let apps = try bar.perform {
            try applicationApi.all(with: token)
        }

        apps.forEach { app in
            console.info("- \(app.name)", newLine: false)
            console.print(" (\(app.repo).vapor.cloud)", newLine: !showIds)
            if showIds {
                let id = app.id?.string ?? "<no-id>"
                console.print(": \(id)")
            }
        }
    }
}
