import Vapor

protocol MyCommand: Command {
    func trigger(with ctx: CommandContext) throws
}

extension MyCommand {
    /// Throwing errors here logs a bunch of information
    /// about how to use the command, but it clutters
    /// the terminal and isn't relavant to the issue
    ///
    /// Here we eat and print any errors but don't throw from here to avoid
    /// this until a more permanent fix can be found
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        do {
            try trigger(with: ctx)
        } catch {
            ctx.console.output("Error:", style: .error)
            ctx.console.output("\(error)".consoleText())
        }
        return .done(on: ctx.container)
    }
}
