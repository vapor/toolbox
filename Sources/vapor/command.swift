
protocol Command {
    static var id: String { get }
    static var help: [String] { get }

    static var dependencies: [String] { get }
    static var subCommands: [Command.Type] { get }
    static func execute(with args: [String], in directory: String)
}

extension Command {
    static var dependencies: [String] { return [] }
    static var help: [String] { return [] }
}

// sub command related methods
extension Command {
    static var subCommands: [Command.Type] { return [] }

    static func executeSubCommand(with args: [String], in directory: String) {
        var iterator = args.makeIterator()
        guard let cmdId = iterator.next() else {
            fail("\(id) requires a sub command:\n" + description)
        }
        guard let subcommand = getCommand(id: cmdId, commands:subCommands) else {
            fail("Unknown \(id) subcommand '\(cmdId)':\n" + description)
        }
        let passthroughArgs = Array(iterator)
        subcommand.execute(with: passthroughArgs, in: directory)
    }
}

extension Command {
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

extension Command {
    static func assertDependenciesSatisfied() {
        for dependency in dependencies where !commandExists(dependency) {
            fail("\(id) requires \(dependency)")
        }
    }
}
