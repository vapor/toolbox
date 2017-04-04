import Foundation

public final class TokenLog: Command {
    public let id = "token"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Cached token metadata for debugging."
    ]

    public let console: ConsoleProtocol

    private let limit = 25

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let access = try getAccess(from: token, with: arguments)
        console.info("Access: ", newLine: true)
        console.print(access)

        console.info("Refresh: ", newLine: true)
        console.print(token.refresh)

        console.info("Expiration: ", newLine: true)
        let expiration = token.expiration.timeIntervalSince1970 - Date().timeIntervalSince1970
        if expiration >= 0 {
            console.success("\(expiration) seconds from now.")
        } else {
            console.warning("\(expiration * -1) seconds ago.")
        }
    }

    func getAccess(from token: Token, with arguments: [String]) throws -> String {
        if arguments.flag("raw") {
            if arguments.flag("full") {
                return token.access
            } else {
                return token.access
                    .makeBytes()
                    .prefix(limit)
                    .makeString()
                    + " ..."
            }
        } else {
            return try token.unwrap().prettyString()
        }
    }
}
