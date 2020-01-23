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
}

public func run() throws {
    signal(SIGINT) { code in
        // kill any background processes running
        if let running = Process.running {
            running.interrupt()
        }
        // kill any foreground execs running
        if let running = execPid {
            kill(running, code)
        }
        exit(code)
    }
    let input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: input)
}
