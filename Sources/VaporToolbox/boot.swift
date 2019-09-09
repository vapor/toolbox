import CloudCommands
import Globals
import AsyncWebSocketClient
import ConsoleKit
import Foundation

final class Main: ToolboxGroup {
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
    
    let help = "welcome to vapor"

    func fallback(using ctx: inout CommandContext) throws {
        ctx.console.output("welcome to vapor.")
        ctx.console.output("use `vapor -h` to see commands")
    }
}

public func run() throws {
    let input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: input)
}
