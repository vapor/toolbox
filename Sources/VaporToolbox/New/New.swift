import ConsoleKit
import Foundation
import Yams

struct New: AnyCommand {
    struct Signature: CommandSignature {
        @Argument(name: "name", help: "Name of project and folder.")
        var name: String
        
        @Option(name: "template", short: "T", help: "The URL of a Git repository to use as a template.")
        var templateURL: String?
        
        @Option(name: "branch", help: "Template repository branch to use.")
        var templateBranch: String?
        
        @Option(name: "output", short: "o", help: "The directory to place the new project in.")
        var outputDirectory: String?
        
        @Flag(name: "no-commit", help: "Skips adding a first commit to the newly created repo.")
        var noCommit: Bool
    }

    let help = "Generates a new app."

    func outputHelp(using context: inout CommandContext) {
        Signature().outputHelp(help: self.help, using: &context)
    }

    func run(using context: inout CommandContext) throws {
        let signature = try Signature(from: &context.input)
        let name = signature.name
        let gitUrl = signature.templateURL ?? "https://github.com/vapor/template"
        let cwd = FileManager.default.currentDirectoryPath
        let workTree = signature.outputDirectory?.asDirectoryURL.path ?? cwd.appendingPathComponents(name)
        let templateTree = workTree.deletingLastPathComponents().appendingPathComponents(".vapor-template")

        context.console.info("Cloning template...")
        try? FileManager.default.removeItem(atPath: templateTree)
        let gitBranch = signature.templateBranch ?? "main"
        _ = try Process.git.clone(repo: gitUrl, toFolder: templateTree, branch: gitBranch)

        if FileManager.default.fileExists(atPath: templateTree.appendingPathComponents("manifest.yml")) {
            try FileManager.default.createDirectory(atPath: workTree, withIntermediateDirectories: false, attributes: nil)
            let yaml = try String(contentsOf: templateTree.appendingPathComponents("manifest.yml").asFileURL, encoding: .utf8)
            let manifest = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)
            let scaffolder = TemplateScaffolder(console: context.console, manifest: manifest)
            try scaffolder.scaffold(
                name: name, 
                from: templateTree.trailingSlash, 
                to: workTree.trailingSlash,
                using: &context.input
            )
            try FileManager.default.removeItem(atPath: templateTree)
        } else {
            try FileManager.default.moveItem(atPath: templateTree, toPath: workTree)
        }

        guard context.input.arguments.isEmpty else {
            throw "Too many arguments: \(context.input.arguments.joined(separator: " "))"
        }
        
        // clear existing git history
        let gitDir = workTree.appendingPathComponents(".git")

        context.console.info("Creating git repository")
        if FileManager.default.fileExists(atPath: gitDir) {
            try FileManager.default.removeItem(atPath: gitDir)
        }
        _ = try Process.git.create(gitDir: gitDir)

        // first commit
        if !signature.noCommit {
            context.console.info("Adding first commit")
            try Process.git.commit(gitDir: gitDir, workTree: workTree, msg: "first commit")
        }
        
        // print the Droplet
        var copy = context
        try PrintDroplet().run(using: &copy)
        
        // figure out the shortest relative path to the new project
        var cdInstruction = workTree.lastPathComponent
        switch workTree.deletingLastPathComponents(1).commonPrefix(with: cwd).trailingSlash {
            case cwd.trailingSlash: // is in current directory
                break
            case cwd.deletingLastPathComponents(1).trailingSlash: // reachable from one level up
                cdInstruction = "..".appendingPathComponents(workTree.pathComponents.suffix(1))
            case cwd.deletingLastPathComponents(2).trailingSlash: // reachable from two levels up
                cdInstruction = "../..".appendingPathComponents(workTree.pathComponents.suffix(2))
            default: // too distant to be worth expressing as a relative path
                cdInstruction = workTree
        }
        
        // print info
        context.console.center([
            "Project " + name.consoleText(.info) + " has been created!",
            "",
            "Use " + "cd \(Process.shell.escapeshellarg(cdInstruction))".consoleText(.info) + " to enter the project directory",
            "Use " + "\(CommandLine.arguments[0]) xcode".consoleText(.info) + " to open the project in Xcode",
        ]).forEach { context.console.output($0) }
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

