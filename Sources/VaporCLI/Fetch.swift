import Console

public final class Fetch: Command {
    public let id = "fetch"

    public let signature: [Argument] = [
        Option(name: "clean", help: ["Cleans the project before fetching."])
    ]

    public let help: [String] = [
        "Fetches the application's dependencies."
    ]

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        let depBar = console.loadingBar(title: "Fetch Dependencies")
        depBar.start()

        var output = ""
        do {
            output = try console.subexecute("swift package fetch")
            depBar.finish()
        } catch ConsoleError.execute(_) {
            depBar.fail()
            console.print(output)
            throw Error.general("Could not fetch dependencies.")
        }
    }
    
}
