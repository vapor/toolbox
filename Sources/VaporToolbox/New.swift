import Console
import libc

public final class New: Command {
    public let id = "new"

    public let defaultTemplate = "https://github.com/vapor/api-template"

    public let signature: [Argument]

    public let help: [String] = [
        "Creates a new Vapor application from a template.",
        "Use --template=repo/template for github templates",
        "Use --template=full-url-here.git for non github templates",
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
            ]),
            Option(name: "branch", help: [
                "An optional branch to specify when cloning",
            ]),
            Option(name: "tag", help: [
                "An optional tag to specify when cloning",
            ])
        ]
    }

    public func run(arguments: [String]) throws {
        let template = try loadTemplate(arguments: arguments)
        let name = try value("name", from: arguments)
        let gitDir = "--git-dir=./\(name)/.git"
        let workTree = "--work-tree=./\(name)"

        let isVerbose = arguments.isVerbose
        let cloneBar = console.loadingBar(title: "Cloning Template", animated: !isVerbose)
        cloneBar.start()

        do {
            _ = try console.execute(verbose: isVerbose, program: "git", arguments: ["clone", "\(template)", "\(name)"])

            if let checkout = arguments.options["tag"]?.string ?? arguments.options["branch"]?.string {
                _ = try console.execute(
                    verbose: isVerbose,
                    program: "git",
                    arguments: [gitDir, workTree, "checkout", checkout]
                )
            }

            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", "\(name)/.git"])

            cloneBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            cloneBar.fail()
            throw ToolboxError.general(error.trim())
        } catch {
            // prevents foreground executions from logging 'Done' instead of 'Failed'
            cloneBar.fail()
            throw error
        }

        let repository = console.loadingBar(title: "Updating Package Name", animated: !isVerbose)
        repository.start()
        do {
            let file = "\(name)/Package.swift"
            var manifest = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "cat \(file)"])
            manifest = manifest.components(separatedBy: "VaporApp").joined(separator: name)
            manifest = manifest.components(separatedBy: "\"").joined(separator: "\\\"")
            _ = try console.backgroundExecute(program: "/bin/sh", arguments: ["-c", "echo \"\(manifest)\" > \(file)"])
        } catch {
            console.error("Could not update Package.swift file.")
        }
        repository.finish()

        let gitBar = console.loadingBar(title: "Initializing git repository", animated: !isVerbose)
        gitBar.start()
        do {
            _ = try console.execute(verbose: isVerbose, program: "git", arguments: [gitDir, "init"])
            _ = try console.execute(verbose: isVerbose, program: "git", arguments: [gitDir, workTree, "add", "."])
            _ = try console.execute(
                verbose: isVerbose,
                program: "git",
                arguments: [gitDir, workTree, "commit", "-m", "\"created \(name) from template \(template)\""]
            )
            gitBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, let output) {
            gitBar.fail()
            console.warning(output)
            console.warning(error)
            console.error("Could not initialize git repository")
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

    private func loadTemplate(arguments: [String]) throws -> String {
        guard let template = arguments.options["template"]?.string else {
            return defaultTemplate
        }
        return try expand(template: template)
    }

    /**
         http(s)://whatever.com/foo/bar => http(s)://whatever.com/foo/bar
         foo/some-template => https://github.com/foo/some-template
         some-template => https://github.com/vapor/some-template
         some => https://github.com/vapor/some
         if fails, attempts `-template` suffix
         some => https://github.com/vapor/some-template
    */
    private func expand(template: String) throws -> String {
        // if valid URL, use it
        guard !isValid(url: template) else { return template }
        // `/` indicates `owner/repo`
        guard !template.contains("/") else { return "https://github.com/" + template }
        // no '/' indicates vapor default
        let direct = "https://github.com/vapor/" + template
        guard !isValid(url: direct) else { return direct }
        // invalid url attempts `-template` suffix
        return direct + "-template"
    }

    private func isValid(url: String) -> Bool {
        do {
            // http://stackoverflow.com/a/6136861/2611971
            let result = try console.backgroundExecute(
                program: "curl",
                arguments: [
                    "-o",
                    "/dev/null",
                    "--silent",
                    "--head",
                    "--write-out",
                    "'%{http_code}\\n'",
                    url
                ]
            )
            return result.contains("200")
        } catch {
            // yucky...
            return false
        }
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
