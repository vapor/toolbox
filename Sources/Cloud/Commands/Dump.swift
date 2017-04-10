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
            try? applicationApi.hosting.get(forRepo: app.repoName, with: token)
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
            if let id = org.id?.string {
                console.info("  Id: ", newLine: false)
                console.print(id)
            }

            let pros = org.projects(in: projects)
            pros.forEach { pro in
                console.success("  Project:")
                console.info("    Name: ", newLine: false)
                console.print(pro.name)
                console.info("    Color: ", newLine: false)
                console.print(pro.color)

                if let id = pro.id?.string {
                    console.info("    Id: ", newLine: false)
                    console.print(id)
                }

                let apps = pro.applications(in: applications)
                apps.forEach { app in
                    console.success("    Application:")
                    console.info("      Name: ", newLine: false)
                    console.print(app.name)
                    console.info("      Repo: ", newLine: false)
                    console.print(app.repoName)
                    if let id = app.id?.string {
                        console.info("      Id: ", newLine: false)
                        console.print(id)
                    }

                    guard let host = app.hosting(in: hosts) else { return }
                    console.success("      Hosting: ")
                    console.info("          Git: ", newLine: false)
                    console.print(host.gitUrl)
                    if let id = host.id?.string {
                        console.info("          Id: ", newLine: false)
                        console.print(id)
                    }

                    let hostEnvs = host.environments(in: envs)
                    hostEnvs.forEach { env in
                        console.success("          Environment:")
                        console.info("            Name: ", newLine: false)
                        console.print(env.name)
                        console.info("            Branch: ", newLine: false)
                        console.print(env.defaultBranch)
                        console.info("            Id: ", newLine: false)
                        console.print(env.id?.string ?? "<no-id>")
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
            proj.organization.id == id
        }
    }
}

extension Project {
    func applications(in apps: [Application]) -> [Application] {
        return apps.filter { app in
            return app.projectId == id
        }
    }
}

extension Application {
    func hosting(in hosts: [Hosting]) -> Hosting? {
        return hosts
            .lazy
            .filter { host in
                host.application.id == self.id
            }
            .first
    }
}

extension Hosting {
    func environments(in envs: [Environment]) -> [Environment] {
        return envs.filter { $0.hosting.id == id }
    }
}
