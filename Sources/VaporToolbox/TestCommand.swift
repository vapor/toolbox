import Vapor

struct Test: MyCommand {
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Quick tests."]
    
    func trigger(with ctx: CommandContext) throws {
        for i in 0...9 {
            ctx.console.output(i.description.consoleText())
        }
//        ctx.console.pushEphemeral()
        let _ = ctx.console.choose("Pick one", from: ["One", "Two", "Three"])
//        ctx.console.popEphemeral()

        ctx.console.pushEphemeral()
        ctx.console.output("Hey!")
        ctx.console.output("WHy\nNot")
        ctx.console.popEphemeral()
        ctx.console.pushEphemeral()
        let _ = ctx.console.ask("wiped")
        ctx.console.popEphemeral()


        ctx.console.pushEphemeral()
        ctx.console.confirm("asdf")
        ctx.console.popEphemeral()
        throw "bar"
    }
}

//extension Console {
//    func ask(_ prompt: ConsoleText) -> String {
//        pushEphemeral()
//        output(prompt, newLine: true)
//        output("> ".consoleText(.info), newLine: false)
//        let answer = input(isSecure: isSecure)
//        popEphemeral()
//        return prompt
//    }
//}
