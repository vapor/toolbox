let version = "0.6.0"

public struct VaporCLI {
    // this closure assignment is necessary to be able to exclude Xcode on Linux
    public static let commands: [Command.Type] = {
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
    }()
}
