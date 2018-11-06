import Vapor
import CloudCommands

public struct MainGroup: CommandGroup {
    public let commands: Commands = [:]

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

/// Creates an Application to run.
public func boot() -> Future<Application> {
    var services = Services.default()

    var commands = CommandConfig()
    commands.use(CleanCommand(), as: "clean")
    commands.use(GenerateLinuxMain(), as: "linux-main")
    commands.use(CloudCommands.CloudGroup(), as: "cloud")
    commands.use(New(), as: "new")

    // for running quick exec tests
    commands.use(Test(), as: "test")
    services.register(commands)

    return Application.asyncBoot(services: services)
}
