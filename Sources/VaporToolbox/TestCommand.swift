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

class Test: BaseCommand {
    override func trigger() throws {
        throw "bar"
    }
}

class BaseCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Quick tests."]

    private(set) var ctx: CommandContext! = nil

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        self.ctx = ctx
        do {
            try trigger()
        } catch {
            ctx.console.output("Error:", style: .error)
            ctx.console.output("\(error)".consoleText())
        }
        return .done(on: ctx.container)
    }

    open func trigger() throws {
        throw "throwing up this errrrr"
    }
}
