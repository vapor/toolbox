import Vapor
import Globals

struct New: Command {
    var arguments: [CommandArgument] = [
        .argument(name: "name", help: ["What to name your project."])
    ]

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "template", short: "t", default: nil, help: [
            "a specific template to use.",
            "-t repo/template for github templates",
            "-t full-url-here.git for non github templates",
            "-t web to create a new web app",
            "-t auth to create a new authenticated API app",
            "-t api (default) to create a new API"
        ]),
        .value(name: "tag", short: nil, default: nil, help: ["a specific tag to use."]),
        .value(name: "branch", short: "b", default: nil, help: ["a specific brach to use."]),

    ]

    /// See `Command`.
    var help: [String] = [
        "creates a new vapor application from a template.",
        "use `vapor new NameOfYourApp`",
    ]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let name = try ctx.argument("name")
        let template = ctx.template()
        let gitUrl = try template.fullUrl()

        // Cloning
        ctx.console.pushEphemeral()
        ctx.console.output("cloning `\(gitUrl)`...".consoleText())
        let _ = try Git.clone(repo: gitUrl, toFolder: name)
        ctx.console.popEphemeral()
        ctx.console.output("cloned `\(gitUrl)`.".consoleText())

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
            ctx.console.output("checked out `\(checkout)`.".consoleText())
        }

        // clear existing git history
        try Shell.delete("./\(name)/.git")
        let _ = try Git.create(gitDir: gitDir)
        ctx.console.output("created git repository.")
        
        // if leaf.seed file, render template here
        let seedPath = workTree.finished(with: "/") + "leaf.seed"
        
        let next: EventLoopFuture<Void>
        if FileManager.default.fileExists(atPath: seedPath) {
            let renderContext = CommandContext(console: ctx.console, arguments: [:], options: ["path": workTree])
            next = try LeafRenderFolder().run(using: renderContext)
        } else {
            next = ctx.done
        }

        return next.flatMap {
            todo()
            // initialize
//            try Git.commit(
//                gitDir: gitDir,
//                workTree: workTree,
//                msg: "created new vapor project from template `\(gitUrl)`"
//            )
//            ctx.console.output("initialized project.")
//
//            // print the Droplet
//            return try PrintDroplet().run(using: ctx).flatMap {
//                let info = [
//                    "project \"\(name)\" has been created.",
//                    "type `cd \(name)` to enter the project directory.",
//                    "use `vapor cloud deploy` and put your project LIVE!",
//                    "enjoy!",
//                    ]
//
//                //ctx.console.center(info)
//                info.forEach { line in
//                    var command = false
//                    for c in line {
//                        if c == "`" { command = !command }
//
//                        ctx.console.output(
//                            c.description,
//                            style: command && c != "`" ? .info : .plain,
//                            newLine: false
//                        )
//                    }
//                    ctx.console.output("", style: .plain, newLine: true)
//                }
//
//
//                return ctx.done
//            }
        }
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
        case .default: return "https://github.com/vapor/template"
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

struct PrintDroplet: Command {
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Prints a droplet."]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        for line in ctx.console.center(asciiArt) {
            for character in line {
                let style: ConsoleStyle
                if let color = colors[character] {
                    style = ConsoleStyle(color: color, background: nil, isBold: false)
                } else {
                    style = .plain
                }
                ctx.console.output(character.description, style: style, newLine: false)
            }
            ctx.console.output("", style: .plain, newLine: true)
        }
        return ctx.done
    }


    private let asciiArt: [String] = [
        "                                ",
        "               **               ",
        "             **~~**             ",
        "           **~~~~~~**           ",
        "         **~~~~~~~~~~**         ",
        "       **~~~~~~~~~~~~~~**       ",
        "     **~~~~~~~~~~~~~~~~~~**     ",
        "   **~~~~~~~~~~~~~~~~~~~~~~**   ",
        "  **~~~~~~~~~~~~~~~~~~~~~~~~**  ",
        " **~~~~~~~~~~~~~~~~~~~~~~~~~~** ",
        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
        "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
        " **~~~~~~~~~~~~~~~~~~~++++~~~** ",
        "  ***~~~~~~~~~~~~~~~++++~~~***  ",
        "    ****~~~~~~~~~~++++~~****    ",
        "       *****~~~~~~~~~*****      ",
        "          *************         ",
        "                                ",
        " _       __    ___   ___   ___  ",
        // the escaping `\` make these lines look weird,
        // but they're correct
        "\\ \\  /  / /\\  | |_) / / \\ | |_) ",
        " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\ ",
        "   a web framework for Swift    ",
        "                                "
    ]

    private let colors: [Character: ConsoleColor] = [
        "*": .magenta,
        "~": .blue,
        "+": .cyan, // Droplet
        "_": .magenta,
        "/": .magenta,
        "\\": .magenta,
        "|": .magenta,
        "-": .magenta,
        ")": .magenta // Title
    ]
}
