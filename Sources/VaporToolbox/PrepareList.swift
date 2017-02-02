import Foundation
import Console

public final class PrepareList: Command {
    public let id = "list"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Create new database preparation file."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        try listPreparations()
    }

    private func listPreparations() throws {
        do {
            let preparations = try console.backgroundExecute(program: "ls", arguments: [preparationsFolder])
            for preparation in preparations.components(separatedBy: CharacterSet.newlines) {
                try checkPreparationStatus(filename: preparation)
            }
        } catch ConsoleError.backgroundExecute(_) {
            console.warning("No preparations folder found (\(preparationsFolder)).")
        }
    }

    private func checkPreparationStatus(filename: String) throws {
//        filename.removeSubrange(filename.range(of: ".swift"))
//        let parts = filename.components(separatedBy: "_")
//        guard parts.count > 2 else {
//            return
//        }
//        let timestamp = parts.dropFirst(2).joined(separator: "_")

        print(filename)
    }
    
}
