import Vapor
import Globals

struct New: Command {
    var arguments: [CommandArgument] = [
        .argument(name: "name", help: ["What to name your project."])
    ]

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "template", short: "t", default: nil, help: [
            "A specific template to use.",
            "-t repo/template for github templates",
            "-t full-url-here.git for non github templates",
            "-t web to create a new web app",
            "-t auth to create a new authenticated API app",
            "-t api (default) to create a new API"
        ]),
        .value(name: "tag", short: nil, default: nil, help: ["A specific tag to use."]),
        .value(name: "branch", short: "b", default: nil, help: ["A specific brach to use."]),

    ]

    /// See `Command`.
    var help: [String] = [
        "Creates a new vapor application from a template.",
        "use vapor new NameOfYourApp",
    ]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let name = try ctx.argument("name")
        let template = ctx.template()
        let gitUrl = try template.fullUrl()

        // Cloning
        ctx.console.pushEphemeral()
        ctx.console.info("Cloning `\(gitUrl)`...")
        let _ = try Git.clone(repo: gitUrl, toFolder: name)
        ctx.console.popEphemeral()
        ctx.console.info("Cloned `\(gitUrl)`.")

        // used to work on a git repository
        // outside of current path
        let gitDir = "./\(name)/.git"
        let workTree = "./\(name)"

        // Prioritize tag over branch
        let checkout = ctx.options["tag"] ?? ctx.options["branch"]
        if let checkout = checkout {
            let _ = try Git.checkout(
                gitDir: gitDir,
                workTree: workTree,
                checkout: checkout
            )
            ctx.console.output("Checked out `\(checkout)`.".consoleText())
        }

        // clear existing git history
        try Shell.delete("./\(name)/.git")
        let _ = try Git.create(gitDir: gitDir)
        ctx.console.output("Created git repository.")

        // initialize
        try Git.commit(
            gitDir: gitDir,
            workTree: workTree,
            msg: "Created new vapor project from template \(gitUrl)"
        )
        ctx.console.output("Initialized project.")

        // configure cloud?
        return ctx.done
    }

}

extension CommandContext {
    func template() -> Template {
        guard let chosen = options["template"] else { return .default }
        switch chosen {
        case "web": return .web
        case "api": return .api
        case "auth": return .auth
        default: return .custom(repo: chosen)
        }
    }
}


enum Template {
    case `default`, web, api, auth
    case custom(repo: String)

    fileprivate func fullUrl() throws -> String {
        switch self {
        case .default: fallthrough
        case .api: return "https://github.com/vapor/api-template"
        case .web: return "https://github.com/vapor/web-template"
        case .auth: return "https://github.com/vapor/auth-template"
        case .custom(let custom): return try expand(templateUrl: custom)
        }
    }


    /// http(s)://whatever.com/foo/bar => http(s)://whatever.com/foo/bar
    /// foo/some-template => https://github.com/foo/some-template
    /// some-template => https://github.com/vapor/some-template
    /// some => https://github.com/vapor/some
    /// if fails, attempts `-template` suffix
    /// some => https://github.com/vapor/some-template
    private func expand(templateUrl url: String) throws -> String {
        // all ssh urls are custom
        if url.contains("@") { return url }

        // expand github urls, ie: `repo-owner/name-of-repo`
        // becomes `https://github.com/repo-owner/name-of-repo`
        let components = url.split(separator: "/")
        if components.count == 1 { throw "unexpected format, use `repo-owner/name-of-repo`" }

        // if not 2, then it's a full https url
        guard components.count == 2 else { return url }
        return "https://github.com/\(url)"
    }
}

//import Console
//import libc
//
//public final class New: Command {
//    public let id = "new"
//
//    public let defaultTemplate = "https://github.com/vapor/api-template"
//    public let authTemplate = "https://github.com/vapor/auth-template"
//    public let webTemplate = "https://github.com/vapor/web-template"
//
//    public let signature: [Argument]
//
//    public let help: [String] = [
//        "Creates a new Vapor application from a template.",
//        "Use --template=repo/template for github templates",
//        "Use --template=full-url-here.git for non github templates",
//        "Use --web to create a new web app",
//        "Use --auth to create a new authenticated API app",
//        "Use --api (default) to create a new API"
//    ]
//
//    public let console: ConsoleProtocol
//
//    public init(console: ConsoleProtocol) {
//        self.console = console
//
//        signature = [
//            Value(name: "name", help: [
//                "The application's executable name."
//                ]),
//            Option(name: "template", help: [
//                "The template repository to clone.",
//                "Default: \(defaultTemplate)."
//                ]),
//            Option(name: "branch", help: [
//                "An optional branch to specify when cloning",
//                ]),
//            Option(name: "tag", help: [
//                "An optional tag to specify when cloning",
//                ]),
//            Option(name: "web", help: [
//                "Sets the template to the web template: https://github.com/vapor/web-template",
//                ]),
//            Option(name: "auth", help: [
//                "Sets the template to the auth template: https://github.com/vapor/auth-template",
//                ]),
//            Option(name: "api", help: [
//                "(Default) Sets the template to the api template: https://github.com/vapor/api-template",
//                ])
//        ]
//    }
//
//    public func run(arguments: [String]) throws {
//        let template = try loadTemplate(arguments: arguments)
//        let name = try value("name", from: arguments)
//        let gitDir = "--git-dir=./\(name)/.git"
//        let workTree = "--work-tree=./\(name)"
//
//        let isVerbose = arguments.isVerbose
//        let cloneBar = console.loadingBar(title: "Cloning Template", animated: !isVerbose)
//        cloneBar.start()
//
//        do {
//            _ = try console.execute(verbose: isVerbose, program: "git", arguments: ["clone", "\(template)", "\(name)"])
//
//            if let checkout = arguments.options["tag"]?.string ?? arguments.options["branch"]?.string {
//                _ = try console.execute(
//                    verbose: isVerbose,
//                    program: "git",
//                    arguments: [gitDir, workTree, "checkout", checkout]
//                )
//            }
//
//            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "\(name)/.git"])
//
//            cloneBar.finish()
//        } catch ConsoleError.backgroundExecute(_, let error, _) {
//            cloneBar.fail()
//            throw ToolboxError.general(error.trim())
//        } catch {
//            // prevents foreground executions from logging 'Done' instead of 'Failed'
//            cloneBar.fail()
//            throw error
//        }
//
//        let repository = console.loadingBar(title: "Updating Package Name", animated: !isVerbose)
//        repository.start()
//        do {
//            let file = "\(name)/Package.swift"
//            var manifest = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "cat \(file)"])
//            manifest = manifest.components(separatedBy: "VaporApp").joined(separator: name)
//            manifest = manifest.components(separatedBy: "\"").joined(separator: "\\\"")
//            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "echo \"\(manifest)\" > \(file)"])
//        } catch {
//            console.error("Could not update Package.swift file.")
//        }
//        repository.finish()
//
//        let gitBar = console.loadingBar(title: "Initializing git repository", animated: !isVerbose)
//        gitBar.start()
//        do {
//            _ = try console.execute(verbose: isVerbose, program: "git", arguments: [gitDir, "init"])
//            _ = try console.execute(verbose: isVerbose, program: "git", arguments: [gitDir, workTree, "add", "."])
//            _ = try console.execute(
//                verbose: isVerbose,
//                program: "git",
//                arguments: [gitDir, workTree, "commit", "-m", "'created \(name) from template \(template)'"]
//            )
//            gitBar.finish()
//        } catch ConsoleError.backgroundExecute(_, let error, let output) {
//            gitBar.fail()
//            console.warning(output)
//            console.warning(error)
//            console.error("Could not initialize git repository")
//        }
//
//        console.print()
//
//        for line in console.center(asciiArt) {
//            for character in line.characters {
//                let style: ConsoleStyle
//
//                if let color = colors[character] {
//                    style = .custom(color)
//                } else {
//                    style = .plain
//                }
//
//                console.output("\(character)", style: style, newLine: false)
//            }
//            console.print()
//        }
//
//        console.print()
//
//        for line in [
//            "Project \"\(name)\" has been created.",
//            "Type `cd \(name)` to enter the project directory.",
//            "Use `vapor cloud deploy` to host your project for free!",
//            "Enjoy!"
//            ] {
//                console.output(console.center(line))
//        }
//
//        console.print()
//    }
//
//    private func loadTemplate(arguments: [String]) throws -> String {
//        guard let template = arguments.options["template"]?.string else {
//            if let _ = arguments.options["web"] {
//                return webTemplate
//            } else if let _ = arguments.options["auth"] {
//                return authTemplate
//            } else {
//                return defaultTemplate
//            }
//        }
//        return try expand(template: template)
//    }
//
//    /**
//     http(s)://whatever.com/foo/bar => http(s)://whatever.com/foo/bar
//     foo/some-template => https://github.com/foo/some-template
//     some-template => https://github.com/vapor/some-template
//     some => https://github.com/vapor/some
//     if fails, attempts `-template` suffix
//     some => https://github.com/vapor/some-template
//     */
//    private func expand(template: String) throws -> String {
//        // if valid URL, use it
//        guard !isValid(url: template) else { return template }
//        // `/` indicates `owner/repo`
//        guard !template.contains("/") else { return "https://github.com/" + template }
//        // no '/' indicates vapor default
//        let direct = "https://github.com/vapor/" + template
//        guard !isValid(url: direct) else { return direct }
//        // invalid url attempts `-template` suffix
//        return direct + "-template"
//    }
//
//    private func isValid(url: String) -> Bool {
//        do {
//            // http://stackoverflow.com/a/6136861/2611971
//            let result = try console.backgroundExecute(
//                program: "curl",
//                arguments: [
//                    "-o",
//                    "/dev/null",
//                    "--silent",
//                    "--head",
//                    "--write-out",
//                    "'%{http_code}\\n'",
//                    url
//                ]
//            )
//            return result.contains("200")
//        } catch {
//            // yucky...
//            return false
//        }
//    }
//
//    public let asciiArt: [String] = [
//        "               **",
//        "             **~~**",
//        "           **~~~~~~**",
//        "         **~~~~~~~~~~**",
//        "       **~~~~~~~~~~~~~~**",
//        "     **~~~~~~~~~~~~~~~~~~**",
//        "   **~~~~~~~~~~~~~~~~~~~~~~**",
//        "  **~~~~~~~~~~~~~~~~~~~~~~~~**",
//        " **~~~~~~~~~~~~~~~~~~~~~~~~~~**",
//        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
//        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
//        "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
//        " **~~~~~~~~~~~~~~~~~~~++++~~~**",
//        "  ***~~~~~~~~~~~~~~~++++~~~***",
//        "    ****~~~~~~~~~~++++~~****",
//        "       *****~~~~~~~~~*****",
//        "          *************",
//        " ",
//        " _       __    ___   ___   ___",
//        "\\ \\  /  / /\\  | |_) / / \\ | |_)",
//        " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\",
//        "   a web framework for Swift",
//        ]
//
//    public let colors: [Character: ConsoleColor] = [
//        "*": .magenta,
//        "~": .blue,
//        "+": .cyan, // Droplet
//        "_": .magenta,
//        "/": .magenta,
//        "\\": .magenta,
//        "|": .magenta,
//        "-": .magenta,
//        ")": .magenta // Title
//    ]
//}
