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

        try console.execute("cp -R /Users/tanner/Developer/qutheory/vapor/example \(name)")

        let file = "\(name)/Package.swift"

        var manifest = try console.subexecute("cat \(file)")
        manifest = manifest.components(separatedBy: "VaporExample").joined(separator: name)
        manifest = manifest.components(separatedBy: "\"").joined(separator: "\\\"")

        try console.execute("echo \"\(manifest)\" > \(file)")

        console.success("Welcome to Vapor")
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
         " "
    ]

}
