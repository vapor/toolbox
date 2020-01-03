import Globals
import ConsoleKit
import Foundation

final class Main: ToolboxGroup {
    struct Signature: CommandSignature {}
    
    let commands: [String: AnyCommand] = [
        "clean": CleanCommand(),
        "new": New(),
        "xcode": XcodeCommand(),
        "build": BuildCommand(),
        "heroku": Heroku(),
        "run": RunCommand(),
    ]
    
    let help = "Vapor Toolbox (Server-side Swift web framework)"

    func fallback(using ctx: inout CommandContext) throws {
        ctx.console.output("Welcome to vapor.")
        ctx.console.output("Use `vapor -h` to see commands.")
    }
}

public func run() throws {
    signal(SIGINT) { code in
        if let running = Process.running {
            running.interrupt()
        }
        exit(code)
    }
    let input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: input)
}
