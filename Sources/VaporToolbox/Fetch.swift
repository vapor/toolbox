import Console
import Foundation
import libc
import Core

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
        try clean(arguments)
        try fetchWarning()
        try fetch(arguments)
    }

    private func clean(_ arguments: [String]) throws {
        guard arguments.flag("clean") else { return }
        let clean = Clean(console: console)
        try clean.run(arguments: arguments)
    }

    private func fetchWarning() throws {
        do {
            let ls = try console.backgroundExecute(program: "ls", arguments: ["-a", "."])
            if !ls.contains(".build") {
                console.warning("No .build folder, fetch may take a while...")
            }
        } catch ConsoleError.backgroundExecute(_) {
            // do nothing
        }
    }

    private func fetch(_ arguments: [String]) throws {
        let verbose = arguments.verbose
        let depBar = console.loadingBar(title: "Fetching Dependencies", animated: !verbose)
        depBar.start()

        let pass = arguments.removeFlags(["clean", "run", "fetch", "release", "verbose"])
        try console.execute(
            verbose: verbose,
            program: "swift",
            arguments: ["package", "--enable-prefetching", "fetch"] + pass
        )
        depBar.finish()
    }
}

extension Array where Element == String {
    func removeFlags(_ flags: [String]) -> [String] {
        let flags = flags.map { "--\($0)" }
        return filter { argument in
            for flag in flags where argument.hasPrefix(flag) {
                return false
            }
            return true
        }
    }
}

// MARK: Prototypes

extension LoadingBar {
    func track(_ operation: @escaping () throws -> ()) rethrows {
        start()
        defer { finish() }
        try operation()
    }
}
extension ConsoleProtocol {
    func ls(_ arguments: [String]) throws -> String {
        return try backgroundExecute(program: "ls", arguments: arguments)
    }
}

extension ConsoleProtocol {
    public func execute(verbose: Bool, program: String, arguments: [String]) throws  {
        if verbose {
            try foregroundExecute(program: program, arguments: arguments)
        } else {
            _ = try backgroundExecute(program: program, arguments: arguments)
        }
    }
}
