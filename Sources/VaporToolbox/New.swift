import Console

public final class New: Command {
    public let id = "new"

    public let defaultTemplate = "https://github.com/vapor/vapor-example"

    public let signature: [Argument]

    public let help: [String] = [
        "Creates a new Vapor application from a template."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console

        signature = [
            Value(name: "name", help: [
                "The application's executable name."
            ]),
            Option(name: "template", help: [
                "The template repository to clone.",
                "Default: \(defaultTemplate)."
            ])
        ]
    }

    public func run(arguments: [String]) throws {
        let template = arguments.options["template"]?.string ?? defaultTemplate
        let name = try value("name", from: arguments).string ?? ""

        let cloneBar = console.loadingBar(title: "Cloning Template")
        cloneBar.start()

        do {
            _ = try console.backgroundExecute(program: "git", arguments: ["clone", "\(template)", "\(name)"])
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "\(name)/.git"])
            cloneBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            cloneBar.fail()
            throw ToolboxError.general(error.string.trim())
        }

        do {
            let file = "\(name)/Package.swift"

            var manifest = try console.backgroundExecute(program: "cat", arguments: ["\(file)"])
            manifest = manifest.components(separatedBy: "VaporApp").joined(separator: name)
            manifest = manifest.components(separatedBy: "\"").joined(separator: "\\\"")
            _ = try console.backgroundExecute(program: "echo", arguments: ["\"\(manifest)\"", ">", "\(file)"])
        } catch {
            console.error("Could not update Package.swift file.")
        }

        console.print()

        for line in console.center(asciiArt) {
            for character in line.characters {
                let style: ConsoleStyle

                if let color = colors[character] {
                    style = .custom(color)
                } else {
                    style = .plain
                }

                console.output("\(character)", style: style, newLine: false)
            }
            console.print()
        }

        console.print()

        for line in [
            "Project \"\(name)\" has been created.",
            "Type `cd \(name)` to enter the project directory.",
            "Enjoy!"
        ] {
            console.output(console.center(line))
        }

        console.print()
    }

    public let asciiArt: [String] = [
         "               **",
         "             **~~**",
         "           **~~~~~~**",
         "         **~~~~~~~~~~**",
         "       **~~~~~~~~~~~~~~**",
         "     **~~~~~~~~~~~~~~~~~~**",
         "   **~~~~~~~~~~~~~~~~~~~~~~**",
         "  **~~~~~~~~~~~~~~~~~~~~~~~~**",
         " **~~~~~~~~~~~~~~~~~~~~~~~~~~**",
         "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
         "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
         "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
         " **~~~~~~~~~~~~~~~~~~~++++~~~**",
         "  ***~~~~~~~~~~~~~~~++++~~~***",
         "    ****~~~~~~~~~~++++~~****",
         "       *****~~~~~~~~~*****",
         "          *************",
         " ",
         " _       __    ___   ___   ___",
         "\\ \\  /  / /\\  | |_) / / \\ | |_)",
         " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\",
         "   a web framework for Swift",
    ]

    public let colors: [Character: ConsoleColor] = [
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
