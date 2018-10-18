import Vapor

struct Test: MyCommand {
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Quick tests."]
    
    func trigger(with ctx: CommandContext) throws {

        throw "bar"
    }
}
