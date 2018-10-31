import Vapor

struct Test: MyCommand {
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Quick tests."]
    
    func trigger(with ctx: CommandContext) throws {
        let access = CloudApp.Access(with: token, on: container)

        let cloudGitUrl = try Git.cloudUrl()
        return access.matching(cloudGitUrl: cloudGitUrl)
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
