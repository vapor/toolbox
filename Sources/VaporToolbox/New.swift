import Vapor
import Globals
import ConsoleKit

extension Argument where Value == String {
    static let name: Argument = .init(name: "name", help: "what to name your project.")
}

extension CommandContext {
    func arg<V: LosslessStringConvertible>(_ arg: Argument<V>) throws -> String {
        guard let val = arguments[arg.name] else { throw "missing value for argument '\(arg.name)'" }
        return val
    }
}

let templateHelp = [
    "a specific template to use.",
    "-t repo/template for github templates",
    "-t full-url-here.git for non github templates",
    "-t web to create a new web app",
    "-t auth to create a new authenticated API app",
    "-t api (default) to create a new API"
] .joined(separator: "\n")

extension Option where Value == String {
    static let template: Option = .init(name: "template", short: "t", type: .value, help: templateHelp)
    static let tag: Option = .init(name: "tag", short: "T", type: .value, help: "a specific template tag to use.")
    static let branch: Option = .init(name: "branch", short: "b", type: .value, help: "a specific template branch to use.")
}

struct New: Command {
    struct Signature: CommandSignature {
        let name: Argument = .name
        
        // options
        let template: Option = .template
        let tag: Option = .tag
        let branch: Option = .branch
    }
    let signature = Signature()
    let help: String? = "creates a new vapor app from template. use 'vapor new ProjectName'."

    func run(using ctx: Context) throws {
        let name = try ctx.arg(.name)
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
        let checkout = ctx.options.value(.tag) ?? ctx.options.value(.branch)
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
        if FileManager.default.fileExists(atPath: seedPath) {
            var opts = ctx.options
            opts["path"] = workTree
            let next = AnyCommandContext(console: ctx.console, arguments: ctx.arguments, options: opts)
            try LeafRenderFolder().run(using: next)
        }

        // initialize
        try Git.commit(
            gitDir: gitDir,
            workTree: workTree,
            msg: "created new vapor project from template `\(gitUrl)`"
        )
        ctx.console.output("initialized project.")
        
        // print the Droplet
        let next = AnyCommandContext(console: ctx.console, arguments: ctx.arguments, options: ctx.options)
        try PrintDroplet().run(using: next)
        
        // print next info
        let info = [
            "project \"\(name)\" has been created.",
            "type `cd \(name)` to enter the project directory.",
            "use `vapor cloud deploy` and put your project LIVE!",
            "enjoy!",
        ]
        info.forEach { line in
            var command = false
            for c in line {
                if c == "`" { command = !command }
                
                ctx.console.output(
                    c.description,
                    style: command && c != "`" ? .info : .plain,
                    newLine: false
                )
            }
            ctx.console.output("", style: .plain, newLine: true)
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
    struct Signature: CommandSignature {}
    let signature = Signature()
    let help: String? = "prints a droplet."
    
    func run(using ctx: Context) throws {
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
