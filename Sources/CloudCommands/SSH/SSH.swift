import Vapor

public struct SSHGroup: CommandGroup {
    public let commands: Commands = [
        "add": SSHAdd(),
        "list": SSHList(),
        "delete": SSHDelete(),
    ]

    public let options: [CommandOption] = []

    /// See `CommandGroup`.
    public var help: [String] = [
        "Interact with SSH Keys on Vapor Cloud."
    ]

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        ctx.console.info("Interact with SSH Keys on Vapor Cloud.")
        ctx.console.output("Use `vapor cloud ssh -h` to see commands.")
        return ctx.done
    }
}
