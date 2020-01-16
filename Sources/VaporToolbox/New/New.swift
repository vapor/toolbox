import ConsoleKit
import Foundation
import Yams

struct New: Command {
    struct Signature: CommandSignature {
        @Argument(name: "name", help: "Name of project and folder.")
        var name: String
    }

    let help = "Generates a new app."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let name = signature.name
        let gitUrl = "https://github.com/vapor/template"

        // Cloning
        ctx.console.info("Cloning template...")
        let _ = try Process.git.clone(repo: gitUrl, toFolder: "./" + name)

        // used to work on a git repository
        // outside of current path
        let gitDir = "./\(name)/.git"
        let workTree = "./\(name)"

        if FileManager.default.fileExists(atPath: workTree.trailingSlash + "manifest.yml") {
            try? Shell.default.delete(".vapor-template")
            try Shell.default.move(name, to: ".vapor-template")
            try Shell.default.makeDirectory(name)
            let yaml = try Shell.default.readFile(path: ".vapor-template/manifest.yml")
            let manifest = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)
            let cwd = try Shell.default.cwd()
            let scaffolder = TemplateScaffolder(console: ctx.console, manifest: manifest)
            try scaffolder.scaffold(
                name: name,
                from: cwd.trailingSlash + ".vapor-template",
                to: cwd.trailingSlash + name
            )
            try Shell.default.delete(".vapor-template")
        }
        
        // clear existing git history
        ctx.console.info("Creating git repository")
        try Shell.default.delete("./\(name)/.git")
        let _ = try Process.git.create(gitDir: gitDir)

        // initialize
        ctx.console.info("Adding first commit")
        try Process.git.commit(
            gitDir: gitDir,
            workTree: workTree,
            msg: "first commit"
        )
        
        // print the Droplet

        var copy = ctx
        try PrintDroplet().run(using: &copy)
        
        // print info
        ctx.console.center([
            "Project " + name.consoleText(.info) + " has been created!",
            "",
            "Use " + "cd \(name)".consoleText(.info) + " to enter the project directory",
            "Use " + "vapor xcode".consoleText(.info) + " to open the project in Xcode",
        ]).forEach { ctx.console.output($0) }
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

