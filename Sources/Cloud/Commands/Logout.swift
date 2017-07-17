import Foundation
import Core

public final class Logout: Command {
    public let id = "logout"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you out of Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let bar = console.loadingBar(title: "Logging out")
        try bar.perform {
            if FileManager.default.fileExists(atPath: tokenPath) {
                _ = try DataFile.delete(at: tokenPath)
            }
        }
    }
}
