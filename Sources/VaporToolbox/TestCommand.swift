import Vapor

/// Cleans temporary files created by Xcode and SPM.
//struct Test: Command {
//    /// See `Command`.
//    var arguments: [CommandArgument] = []
//
//    /// See `Command`.
//    var options: [CommandOption] = []
//
//    /// See `Command`.
//    var help: [String] = ["Quick tests."]
//
//    /// See `Command`.
//    func run(using ctx: CommandContext) throws -> Future<Void> {
//        print("ok")
//        throw "bar"
//        return .done(on: ctx.container)
//    }
//}

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
