import Console

public final class New: Command {
    public let id = "new"

    public let defaultTemplate = "https://github.com/qutheory/vapor-example"

    public let signature: [Argument]

    public let help: [String] = [
        "Creates a new Vapor application from a template."
    ]

    public let console: Console

    public init(console: Console) {
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
            _ = try console.subexecute("git clone \(template) \(name)")
            cloneBar.finish()
        } catch ConsoleError.subexecute(_, let error) {
            cloneBar.fail()
            throw Error.general(error.trim())
        }

        do {
            let file = "\(name)/Package.swift"

            var manifest = try console.subexecute("cat \(file)")
            manifest = manifest.components(separatedBy: "VaporExample").joined(separator: name)
            manifest = manifest.components(separatedBy: "\"").joined(separator: "\\\"")
            _ = try console.subexecute("echo \"\(manifest)\" > \(file)")
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
