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
    let console = Terminal()
    let input = CommandInput(arguments: CommandLine.arguments)
    do {
        try console.run(Main(), input: input)
    }
    // Handle deprecated commands. Done this way instead of by implementing them as Commands because otherwise
    // there's no way to avoid them showing up in the --help, which is exactly the opposite of what we want.
    catch CommandError.unknownCommand(let command, _) where command == "update" {
        console.output(
            "\("Error:", style: .error) The \"\("update", style: .warning)\" command has been removed. " +
            "Use \"\("swift package update", style: .success)\" instead."
        )
    }
}
