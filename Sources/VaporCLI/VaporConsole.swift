import Console

public final class VaporConsole {
    public static let version = "0.6.0"

    let console: Console
    let shell: Shell

    public let commands: [String: Command.Type]

    public init(console: Console? = nil, shell: Shell? = nil, commands: [String: Command.Type] = [:]) {
        if let console = console {
            self.console = console
        } else {
            self.console = Terminal()
        }

        if let shell = shell {
            self.shell = shell
        } else {
            self.shell = CShell()
        }

        self.commands = commands
    }

    public func run(input: [String]) throws {
        let arguments = input.filter { !$0.hasPrefix("--") }
        var options: [String: OptionValue] = [:]

        for option in input.filter({ $0.hasPrefix("--") }) {
            let parts = option.characters.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: false)

            guard parts.count == 3 else {
                continue
            }

            let token = parts[2].split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)

            let name = String(token[0])

            if token.count == 2 {
                options[name] = String(token[1])
            } else {
                options[name] = true
            }
        }

        var iterator = arguments.makeIterator()

        guard let executable = iterator.next() else {
            throw Error.noExecutable
        }

        guard let id = iterator.next() else {
            if options["help"]?.bool == true {
                help(executable)
                return
            } else {
                throw Error.noCommand
            }
        }

        guard let commandType = commands[id] else {
            throw Error.commandNotFound
        }

        //command.assertDependenciesSatisfied()

        let command = commandType.init(
            console: self,
            shell: shell,
            arguments: Array(iterator),
            options: options
        )

        if options["help"]?.bool == true {
            print("Usage: \(executable) \(id)")
            print()
            command.help()
            print()
        } else {
            try command.run()
        }
    }
}

extension VaporConsole: Console {
    public func output(_ string: String, style: ConsoleStyle, newLine: Bool) {
        console.output(string, style: style, newLine: newLine)
    }

    public func input() -> String {
        return console.input()
    }

    public func clear(_ clear: ConsoleClear) {
        console.clear(clear)
    }
}
