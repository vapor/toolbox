import ArgumentParser
import Foundation
import Yams

@main
struct Toolbox: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A tool for creating Vapor projects.",
        subcommands: [New.self],
        defaultSubcommand: New.self
    )
}

extension Toolbox {
    struct New: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Generates a new app."
        )

        @Argument(help: "Name of project and folder.")
        var name: String

        @OptionGroup(title: "Dependencies Options")
        var dependencies: DependenciesOptions

        @Option(
            name: [.customShort("T"), .long],
            help: ArgumentHelp(
                "The URL of a Git repository to use as a template.",
                valueName: "url"
            )
        )
        var template: String?

        @Option(help: "Template repository branch to use.")
        var branch: String?

        @Option(
            name: .shortAndLong,
            help: ArgumentHelp(
                "The directory to place the new project in.",
                valueName: "path"
            )
        )
        var output: String?

        @Flag(help: "Skips adding a first commit to the newly created repo.")
        var noCommit: Bool = false

        @Flag(help: "Skips adding a Git repository to the project folder.")
        var noGit: Bool = false

        @Flag(name: .shortAndLong, help: "Prints additional information when creating a new project.")
        var verbose: Bool = false

        mutating func run() throws {
            let cwd = URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
            let projectURL =
                if let output {
                    URL(filePath: output, directoryHint: .isDirectory)
                } else {
                    cwd.appending(path: name, directoryHint: .isDirectory)
                }
            let templateURL = projectURL.deletingLastPathComponent().appending(path: ".vapor-template", directoryHint: .isDirectory)
            let gitURL = URL(filePath: try Process.shell.which("git"))

            print("Cloning template...".colored(.cyan))
            try? FileManager.default.removeItem(at: templateURL)  // Is this safe?
            var cloneArgs = ["clone"]
            if let branch {
                cloneArgs.append("--branch")
                cloneArgs.append(branch)
            }
            cloneArgs.append(template ?? "https://github.com/vapor/template")
            cloneArgs.append(templateURL.path())
            try Process.runUntilExit(gitURL, arguments: cloneArgs)

            if FileManager.default.fileExists(atPath: templateURL.appending(path: "manifest.yml").path()) {
                defer { try? FileManager.default.removeItem(at: templateURL) }

                try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: false)

                let yaml = try String(contentsOf: templateURL.appending(path: "manifest.yml"), encoding: .utf8)
                let manifest = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)

                let renderer = TemplateRenderer(manifest: manifest, verbose: verbose)
                try renderer.render(
                    project: name,
                    from: templateURL,
                    to: projectURL,
                    dependencies: dependencies
                )
            } else {
                // If the template doesn't have a manifest (AKA doesn't need templating), just move the files
                try FileManager.default.moveItem(at: templateURL, to: projectURL)
            }

            if !noGit {
                let gitDir = projectURL.appending(path: ".git").path()

                print("Creating git repository".colored(.cyan))
                if FileManager.default.fileExists(atPath: gitDir) {
                    try FileManager.default.removeItem(atPath: gitDir)  // Clear existing git history
                }
                try Process.runUntilExit(gitURL, arguments: ["--git-dir=\(gitDir)", "init"])

                if !noCommit {
                    print("Adding first commit".colored(.cyan))
                    let gitDirFlag = "--git-dir=\(gitDir)"
                    let workTreeFlag = "--work-tree=\(projectURL.path())"
                    try Process.runUntilExit(gitURL, arguments: [gitDirFlag, workTreeFlag, "add", "."])
                    try Process.runUntilExit(gitURL, arguments: [gitDirFlag, workTreeFlag, "commit", "-m", "Generate Vapor project."])
                }
            }

            // Figure out the shortest relative path to the new project
            let cwdPath = cwd.path()
            var cdInstruction = projectURL.path()
            if projectURL.deletingLastPathComponent().path().commonPrefix(with: cwdPath) == cwdPath {
                cdInstruction = projectURL.lastPathComponent  // Is in current directory
            }

            if verbose { printDroplet() }
            print("Project \(name.colored(.cyan)) has been created!")
            if verbose { print() }
            print("Use " + "cd \(Process.shell.escapeshellarg(cdInstruction))".colored(.cyan) + " to enter the project directory")
            print(
                "Then open your project, for example if using Xcode type "
                    + "open Package.swift".colored(.cyan)
                    + " or "
                    + "code .".colored(.cyan)
                    + " if using VSCode"
            )
        }

        struct DependenciesOptions: ParsableArguments {
            @Option(
                help: ArgumentHelp(
                    "The database to use.",
                    discussion: "If no database is provided, the Fluent ORM will not be included in the project.",
                    valueName: "database"
                )
            )
            var fluent: Database?

            @Flag(inversion: .prefixedNo, help: "Use Leaf for templating.")
            var leaf: Bool
        }
    }
}

private func printDroplet() {
    let asciiArt: [String] = [
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
        // the escaping `\` make these lines look weird, but they're correct
        "\\ \\  /  / /\\  | |_) / / \\ | |_) ",
        " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\ ",
        "   a web framework for Swift    ",
        "                                ",
    ]

    let colors: [Character: ANSIColor] = [
        "*": .magenta,
        "~": .blue,
        "+": .cyan,
        "_": .magenta,
        "/": .magenta,
        "\\": .magenta,
        "|": .magenta,
        "-": .magenta,
        ")": .magenta,
    ]

    for line in asciiArt {
        for char in line {
            print(char.colored(colors[char]), terminator: "")
        }
        print()
    }
}
