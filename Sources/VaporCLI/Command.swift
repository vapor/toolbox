import Console

public class Command {
    public let console: Console
    public let shell: Shell

    public let arguments: [String]
    public let options: [String: OptionValue]

    public required init(
        console: Console,
        shell: Shell,
        arguments: [String],
        options: [String: OptionValue]
    ) {
        self.console = console
        self.shell = shell
        self.arguments = arguments
        self.options = options
    }

    public func run() throws {

    }

    public func help() {

    }
}

extension Command {
    public func argument(_ name: String) throws -> String {
        return ""
    }

    public func option(_ name: String) -> OptionValue? {
        return options[name]
    }

    public func flag(_ name: String) -> Bool {
        return option(name)?.bool == true
    }
}

extension Command: Console {
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
