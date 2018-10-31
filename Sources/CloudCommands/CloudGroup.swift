import Vapor

//extension String: Error {}

public struct CloudGroup: CommandGroup {
    public let commands: Commands = [
        // USER COMMANDS
        "login": CloudLogin(),
        "signup": CloudSignup(),
        "me": Me(),
        "reset-password": ResetPassword(),
        "dump-token": DumpToken(),

        
//        // global context
//        "login" : CloudLogin(),
//        "signup": CloudSignup(),
//        "me": Me(),
//        "dump-token": DumpToken(),
//        "ssh": CloudSSHGroup(),
//        "apps": CloudAppsGroup(),
//        "orgs": CloudOrgsGroup(),
//        "envs": CloudEnvsGroup(),
//        // current or no context
//        "deploy": CloudDeploy(),
//        // current context
//        "detect": detectApplication,
//        "set-remote": cloudSetRemote,
    ]

    public let options: [CommandOption] = []

    /// See `CommandGroup`.
    public var help: [String] = [
        "Interact with Vapor Cloud."
    ]

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        ctx.console.info("Welcome to Cloud.")
        ctx.console.output("Use `vapor cloud -h` to see commands.")
        let cloud = [
            "   _  _         ",
            "  ( `   )_      ",
            " (    )    `)   ",
            "(_   (_ .  _) _)",
            "                ",
        ]
        let centered = ctx.console.center(cloud)
        centered.map { $0.consoleText() } .forEach(ctx.console.output)
        return .done(on: ctx.container)
    }
}
