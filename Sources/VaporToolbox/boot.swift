import CloudCommands
import Globals
import AsyncWebSocketClient
import ConsoleKit
import Foundation

final class Main: CommandGroup {
    struct Signature: CommandSignature {}
    
    let commands: [String: AnyCommand] = [
        "clean": CleanCommand(),
        "linux-main": GenerateLinuxMain(),
        "cloud": CloudGroup(),
        "new": New(),
        "drop": PrintDroplet(),
        "test": Test(),
        "xcode": XcodeCommand(),
        "build": BuildCommand(),
        "leaf": LeafGroup()
    ]
    
    let help = "main"
    
    func outputHelp(using ctx: inout CommandContext) throws {
        ctx.console.output("welcome to vapor.")
        ctx.console.output("use `vapor -h` to see commands")
    }
}

public func run() throws {
    let isGit = Git.isGitRepository()
    print("is git: \(isGit)")
//    let result = try Process.run("git", args: ["status"])
//    print("result: \(result)")
    let input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: input)
}
