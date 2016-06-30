
public protocol Command {
    static var id: String { get }
    static var help: [String] { get }

    static var dependencies: [String] { get }
    static var subCommands: [Command.Type] { get }
    static func execute(with args: [String], in shell: PosixSubsystem) throws
}

public extension Command {
    static func subCommand(for id: String) -> Command.Type? {
        return subCommands
            .lazy
            .filter { $0.id == id }
            .first
    }
}

public extension Command {
    static func execute(with args: [String]) throws {
        try execute(with: args, in: Shell())
    }
}

public extension Command {
    static var dependencies: [String] { return [] }
    static var help: [String] { return [] }
}

// sub command related methods
public extension Command {
    static var subCommands: [Command.Type] { return [] }

    static func executeSubCommand(with args: [String], in shell: PosixSubsystem) throws {
        var iterator = args.makeIterator()
        guard let cmdId = iterator.next() else {
            throw Error.failed("\(id) requires a sub command:\n" + description)
        }
        guard let subcommand = subCommand(for: cmdId) else {
            throw Error.failed("Unknown \(id) subcommand '\(cmdId)':\n" + description)
        }

        try subcommand.assertDependenciesSatisfied()

        let passthroughArgs = Array(iterator)
        try subcommand.execute(with: passthroughArgs, in: shell)
    }
}

public extension Command {
    static var description: String {
        // Sub Commands
        let subCommandRows: [String] = subCommands.map { subCommand in
            var output = "      \(subCommand.id.colored(with: .blue)):"

            if subCommand.help.count > 0 {
                output += "\n"
                output += subCommand.help.map { row in
                    return "          \(row)"
                    }.joined(separator: "\n")
                output += "\n"
            }

            return output
        }
        let subCommandOutput = "\n" + subCommandRows.joined(separator: "\n")

        // Command
        var output = "  \(id.colored(with: .magenta)):"

        if help.count > 0 {
            output += "\n"

            output += help.map { row in
                return "      \(row)"
                }.joined(separator: "\n")

            output += "\n"
        }

        output += subCommandOutput

        return output
    }
}

public extension Command {
    static func assertDependenciesSatisfied() throws {
        for dependency in dependencies where !Shell().commandExists(dependency) {
            throw Error.failed("\(id) requires \(dependency)")
        }
    }
}
