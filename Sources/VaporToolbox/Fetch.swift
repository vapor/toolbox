import Console

public final class Fetch: Command {
    public let id = "fetch"

    public let signature: [Argument] = [
        Option(name: "clean", help: ["Cleans the project before fetching."])
    ]

    public let help: [String] = [
        "Fetches the application's dependencies."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        do {
            let ls = try console.backgroundExecute(program: "ls -a", arguments: ["."])
            #if swift(>=3.1)
                if !ls.contains(".buid") {
                    console.warning("No .build folder, fetch may take a while...")
                }
            #else
                if !ls.contains("Packages") {
                    console.warning("No Packages folder, fetch may take a while...")
                }
            #endif
        } catch ConsoleError.backgroundExecute(_) {
            // do nothing
        }

        let depBar = console.loadingBar(title: "Fetching Dependencies")
        depBar.start()

        do {
            #if swift(>=3.1)
                _ = try console.backgroundExecute(program: "swift", arguments: ["package", "--enable-prefetching", "fetch"])
            #else
                _ = try console.backgroundExecute(program: "swift", arguments: ["package", "fetch"])
            #endif
            depBar.finish()
        } catch ConsoleError.backgroundExecute(_, let message, _) {
            let message = message.string
            depBar.fail()
            if message.contains("dependency graph could not be satisfied because an update") {
                console.info("Try cleaning your project first.")
            } else if message.contains("The dependency graph could not be satisfied") {
                console.info("Check your dependencies' Package.swift files to see where the conflict is.")
            }
            throw ToolboxError.general(message.trim())
        }
    }
    
}
