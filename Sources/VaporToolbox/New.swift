import Globals
import ConsoleKit
import Foundation

let templateHelp = [
    "a specific template to use.",
    "-t repo/template for github templates",
    "-t full-url-here.git for non github templates",
    "-t web to create a new web app",
    "-t auth to create a new authenticated API app",
    "-t api (default) to create a new API"
] .joined(separator: "\n")

import Yams

struct New: Command {
    struct Signature: CommandSignature {
        @Argument(name: "name", help: "new folder to be created")
        var name: String
        
        // options
        @Option(name: "template", short: "t", help: templateHelp)
        var template: String
        @Option(name: "tag", short: "t", help: "a specific tag to use, if desired.")
        var tag: String
        @Option(name: "branch", short: "b", help: "a specific branch to use, if desired.")
        var branch: String
    }

    let help = "creates a new vapor app from template. use 'vapor new project-name'."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let name = signature.name
        let template = signature.expandedTemplate()
        let gitUrl = try template.fullUrl()

        // Cloning
        ctx.console.pushEphemeral()
        ctx.console.output("Fetching \(gitUrl)...".consoleText())
        let _ = try Git.clone(repo: gitUrl, toFolder: "./" + name)
        ctx.console.popEphemeral()

        // used to work on a git repository
        // outside of current path
        let gitDir = "./\(name)/.git"
        let workTree = "./\(name)"

        // Prioritize tag over branch
        let checkout = signature.tag ?? signature.branch
        if let checkout = checkout {
            let _ = try Git.checkout(
                gitDir: gitDir,
                workTree: workTree,
                checkout: checkout
            )
            ctx.console.output("checked out `\(checkout)`.".consoleText())
        }

        if FileManager.default.fileExists(atPath: workTree.trailingSlash + "manifest.yml") {
            try? Shell.delete(".vapor-template")
            try Shell.move(name, to: ".vapor-template")
            try Shell.makeDirectory(name)
            let yaml = try Shell.readFile(path: ".vapor-template/manifest.yml")
            let manifest = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)
            let cwd = try Shell.cwd()
            let scaffolder = TemplateScaffolder(console: ctx.console, manifest: manifest)
            try scaffolder.scaffold(
                name: name,
                from: cwd.trailingSlash + ".vapor-template",
                to: cwd.trailingSlash + name
            )
            try Shell.delete(".vapor-template")
        } else if FileManager.default.fileExists(atPath: workTree.trailingSlash + "leaf.seed") {
            // if leaf.seed file, render template here
            let raw = ctx.input.arguments + ["-p", workTree]
            var input = CommandInput(arguments: [ctx.input.executable] + raw)
            let renderSignature = try LeafRenderFolder.Signature.init(from: &input)
            try LeafRenderFolder().run(using: ctx, signature: renderSignature)
        }

        // clear existing git history
        ctx.console.pushEphemeral()
        ctx.console.output("Creating git repository")
        try Shell.delete("./\(name)/.git")
        let _ = try Git.create(gitDir: gitDir)
        ctx.console.popEphemeral()


        // initialize
        ctx.console.pushEphemeral()
        ctx.console.output("Adding first commit")
        try Git.commit(
            gitDir: gitDir,
            workTree: workTree,
            msg: "created new vapor project from template: \(gitUrl)"
        )
        ctx.console.popEphemeral()
        
        // print the Droplet

        var copy = ctx
        try PrintDroplet().run(using: &copy)
        
        // print info
        ctx.console.center([
            "Project " + name.consoleText(.info) + " has been created!",
            "",
            "Use " + "cd \(name)".consoleText(.info) + " to enter the project directory",
            "Use " + "open Package.swift".consoleText(.info) + " to open the project in Xcode",
            "Use " + "vapor cloud deploy".consoleText(.info) + " to deploy to the Internet"
        ]).forEach { ctx.console.output($0) }
    }

}

extension New.Signature {
    func expandedTemplate() -> Template {
        guard let chosen = self.template else { return .default }
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
    let help = "prints a droplet."
    
    func run(using ctx: CommandContext, signature: Signature) throws {
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

extension Console {
    func center(_ strings: [ConsoleText], padding: String = " ") -> [ConsoleText] {
        var lines = strings

        // Make sure there's more than one line
        guard lines.count > 0 else {
            return []
        }

        // Find the longest line
        var longestLine = 0
        for line in lines {
            if line.description.count > longestLine {
                longestLine = line.description.count
            }
        }

        // Calculate the padding and make sure it's greater than or equal to 0
        let minPaddingCount = max(0, (size.width - longestLine) / 2)

        // Apply the padding to each line
        for i in 0..<lines.count {
            let diff = (longestLine - lines[i].description.count) / 2
            for _ in 0..<(minPaddingCount + diff) {
                lines[i].fragments.insert(.init(string: padding), at: 0)
            }
        }

        return lines
    }
}

