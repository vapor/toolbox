let version = "0.6.0"

public struct VaporCLI {
    // this closure assignment is necessary to be able to exclude Xcode on Linux
    public static let commands: [Command.Type] = {
        var c = [Command.Type]()
        c.append(Help)
        c.append(Version)
        c.append(Clean)
        c.append(Build)
        c.append(Run)
        c.append(New)
        c.append(Update)
        #if os(OSX)
            c.append(Xcode)
        #endif
        c.append(Heroku)
        c.append(Docker)
        return c
    }()
}
