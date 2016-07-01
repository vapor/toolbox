let version = "0.6.0"

public struct VaporCLI: Command {
    public static var id = "vapor"

    public static var subCommands: [Command.Type] {
        var c = [Command.Type]()
        c.append(Help.self)
        c.append(Version.self)
        c.append(Clean.self)
        c.append(Build.self)
        c.append(Run.self)
        c.append(New.self)
        c.append(Update.self)
        #if os(OSX)
            c.append(Xcode.self)
        #endif
        c.append(Heroku.self)
        c.append(Docker.self)
        return c
    }

    public static func execute(with args: [String], in shell: PosixSubsystem) throws {
        let passThroughArguments = Array(args.dropFirst())
        if passThroughArguments.count > 0 {
            try executeSubCommand(with: passThroughArguments, in: shell)
        } else {
            throw Error.failed("Please specify a command\n" + self.usage)
        }
    }

    public static var usage: String {
        return "Usage: \(id) [\(VaporCLI.subCommands.map({ $0.id }).joined(separator: "|"))]"
    }

}
