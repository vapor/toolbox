import Console

public final class Meta: Command {
    public static let id = "self"

    public let console: Console

    public let subcommands: [Command]

    public init(console: Console, executable: String) {
        self.console = console
        self.subcommands = [
            MetaInstall(console: console, executable: executable),
            MetaUpdate(console: console, executable: executable)
        ]
    }

    public func run(arguments: [String]) throws {
        try console.run(executable: self.dynamicType.id, commands: subcommands, arguments: arguments)
    }
}


public final class MetaInstall: Command {
    public static let id = "install"

    public let console: Console
    public let executable: String

    public init(console: Console, executable: String) {
        self.console = console
        self.executable = executable
    }

    public func run(arguments: [String]) throws {
        let file: String
        do {
            file = try console.subexecute("ls \(executable)")
        } catch ConsoleError.execute(_) {
            do {
                file = try console.subexecute("which \(executable)")
            } catch ConsoleError.execute(_) {
                throw Error.general("Could not locate executable.")
            }
        }

        let current = String(file.characters.dropLast())

        let command = "mv \(current) /usr/local/bin/vapor"
        do {
            try console.execute(command)
        } catch ConsoleError.execute(_) {
            console.warning("Install failed, trying sudo")
            do {
                try console.execute("sudo \(command)")
            } catch ConsoleError.execute(_) {
                throw Error.general("Installation failed.")
            }
        }
    }

    public var help: [String] = [
        "Installs the CLI into /usr/local/bin"
    ]
}

public final class MetaUpdate: Command {
    public static let id = "update"

    public let console: Console
    public let executable: String

    public init(console: Console, executable: String) {
        self.console = console
        self.executable = executable
    }

    public func run(arguments: [String]) throws {

    }

    public var help: [String] = [
        ""
    ]
}
