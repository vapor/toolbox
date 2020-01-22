import Foundation

extension Process {
    static var heroku: Heroku {
        .init()
    }

    struct Heroku {
        func run(_ command: String, _ arguments: String...) throws -> String {
            try self.run(command, arguments)
        }

        func run(_ command: String, _ arguments: [String]) throws -> String {
            try Process.run(Process.shell.which("heroku"), [command] + arguments)
        }
    }
}
