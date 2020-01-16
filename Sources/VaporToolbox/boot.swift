import ConsoleKit
import Foundation

final class Main: CommandGroup {
    struct Signature: CommandSignature {}
    
    let commands: [String: AnyCommand] = [
        "clean": Clean(),
        "new": New(),
        "xcode": Xcode(),
        "build": Build(),
        "heroku": Heroku(),
        "run": Run(),
        "supervisor": Supervisor(),
    ]
    
    let help = "Vapor Toolbox (Server-side Swift web framework)"

    func run(using context: inout CommandContext) throws {
        context.console.output("Welcome to vapor.")
        context.console.output("Use `vapor -h` to see commands.")
    }
}

public func run() throws {
    signal(SIGINT) { code in
        if let running = Process.running {
            running.interrupt()
        }
    }
    let input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: input)
}
