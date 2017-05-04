extension ConsoleProtocol {
    /// Dynamically chooses an application based on
    /// input arguments, git in the working directory,
    /// and lists pulled from cloud API.
    func application(
        for arguments: [String],
        using cloudFactory: CloudAPIFactory
    ) throws -> Application {
        let app: Application
        
        if let repoName = arguments.option("app")?.string {
            app = try cloudFactory
                .makeAuthedClient(with: self)
                .application(withRepoName: repoName)
        } else {
            // picks an application by choosing
            // a project and then application
            func chooseFromList() throws -> Application {
                let apps = try loadingBar(title: "Loading applications", ephemeral: true) {
                    return try cloudFactory
                        .makeAuthedClient(with: self)
                        .applications()
                }
                
                guard apps.count > 0 else {
                    warning("No applications found.")
                    detail("Create application", "vapor cloud create app")
                    if confirm("Would you like to create an application now?") {
                        let create = CreateApplication(self, cloudFactory)
                        return try create.createApplication(with: arguments)
                    } else {
                        throw "Application required"
                    }
                }
                
                return try giveChoice(
                    title: "Which application?",
                    in: apps
                )
            }

            if projectInfo.isVaporProject() {
                print("Vapor project detected, to manually choose an application use the --app option.")
                
                if !gitInfo.isGitProject(){
                    warning("This Vapor project is not managed by Git.")
                    print("To deploy to Vapor cloud, you must put this project under version control.")
                    if confirm("Would you like to initialize git?") {
                        _ = try backgroundExecute(program: "git", arguments: ["init"])
                        success("Git initialized")
                    } else {
                        throw "Git required"
                    }
                }
                
                var remotes = try gitInfo.remoteUrls()
                if remotes.count == 0 {
                    warning("No Git remotes found.")
                    print("To deploy to Vapor Cloud, you must push your Git repo to a remote.")
                    print("You can host your Git repo for free at https://github.com/new.")
                    if confirm("Would you like to add a remote?") {
                        info("Opening GitHub...")
                        _ = try open("https://github.com/new")
                        print("After you create the GitHub repo, paste the SSH URL here.")
                        print("ex: git@github.com:me/my-project.git")
                        let origin = ask("GitHub origin url").string
                        try foregroundExecute(program: "git", arguments: ["remote", "add", "origin", origin])
                        do {
                            try foregroundExecute(program: "git", arguments: ["add", "."])
                            try foregroundExecute(program: "git", arguments: ["commit", "-am", "\"first commit\""])
                        } catch {}
                        try foregroundExecute(program: "git", arguments: ["push", "-u", "origin", "master"])
                        success("Added Git origin: \(origin)")
                        remotes = try gitInfo.remoteUrls()
                    } else {
                        throw "Git remote required"
                    }
                }
                
                // make sure application is up to date
                try warnGitClean()
                
                // attempt to find app based on
                // git information
                var apps = try cloudFactory
                    .makeAuthedClient(with: self)
                    .applications(gitRemotes: remotes, using: self)

      
                // automatically choose app
                // if only one option was returned
                switch apps.count {
                case 0:
                    warning("No applications matching Git remotes found.")
                    for remote in remotes {
                        print("    - \(remote)")
                    }
                    detail("Create application", "vapor cloud create app")
                    if confirm("Would you like to create an application now?") {
                        let create = CreateApplication(self, cloudFactory)
                        app = try create.createApplication(with: arguments)
                    } else {
                        throw "Application required"
                    }
                    
                case 1:
                    app = apps[0]
                default:
                    app = try giveChoice(
                        title: "Which application?",
                        in: apps
                    )
                }
            } else {
                print("Run this command from inside of a Vapor project to automatically detect the application.")
                app = try chooseFromList()
            }    
        }
        
        detail("app", app.name)
        return app
    }
}

extension Application: CustomStringConvertible {
    public var description: String {
        return "\(name) (\(repoName).vapor.cloud)"
    }
}

extension CloudAPI {
    func applications(gitRemotes: [String], using console: ConsoleProtocol) throws -> [Application] {
        return try gitRemotes.flatMap { url in
            try console.loadingBar(title: "Loading applications", ephemeral: true) {
                return try self.applications(gitURL: url)
            }
        }
    }
}
