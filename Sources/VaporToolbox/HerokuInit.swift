import Console

public final class HerokuInit: Command {
    public let id = "init"

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

        let tmpFile = "/var/tmp/vaporFetchOutput.log"

        do {
            _ = try console.subexecute("swift package fetch > \(tmpFile) 2>&1")
            depBar.finish()
        } catch ConsoleError.subexecute(_) {
            depBar.fail()
            _ = try console.subexecute("tail \(tmpFile)")
            throw Error.general("Could not fetch dependencies.")
        }
    }
    
}
