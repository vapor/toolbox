import Foundation

extension Process {
    static var swift: Swift {
        .init()
    }

    struct Swift {
        func run(_ command: String, _ arguments: String...) throws -> String {
            try self.run(command, arguments)
        }
        
        func run(_ command: String, _ arguments: [String]) throws -> String {
            try Process.run(Process.shell.which("swift"), [command] + arguments)
        }
    }
}

extension Process.Swift {
    var package: Package {
        .init(swift: self)
    }

    struct Package {
        let swift: Process.Swift

        struct Dump: Codable {
            let name: String
        }

        func dump() throws -> Dump {
            let dump = try self.run("dump-package")
            return try JSONDecoder().decode(Dump.self, from: Data(dump.utf8))
        }

        func run(_ command: String, _ arguments: String...) throws -> String {
            try self.run(command, arguments)
        }

        func run(_ command: String, _ arguments: [String]) throws -> String {
            try self.swift.run("package", [command] + arguments)
        }
    }
}
