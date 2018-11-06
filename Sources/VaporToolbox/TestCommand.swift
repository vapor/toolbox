import Vapor

struct Test: MyCommand {
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Quick tests. Probably don't call this."]
    
    func trigger(with ctx: CommandContext) throws {
//        let access = CloudApp.Access(with: token, on: container)
//
//        let cloudGitUrl = try Git.cloudUrl()
//        return access.matching(cloudGitUrl: cloudGitUrl)
    }
}
