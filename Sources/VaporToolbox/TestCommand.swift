import Vapor

struct Test: Command {

    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = [
        "Quick tests. Probably don't call this. It shouldn't be here."
    ]

    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        print("test ran")
        return ctx.done
    }
}
