import ConsoleKit
import Foundation

final class Toolbox: CommandGroup {
    struct Signature: CommandSignature {
        @Flag(name: "version", help: "Prints Vapor toolbox and framework versions.")
        var version: Bool
    }
    
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
        let signature = try Signature(from: &context.input)
        if signature.version {
            self.outputFrameworkVersion(context: context)
            self.outputToolboxVersion(context: context)
        } else if let command = try self.commmand(using: &context) {
            try command.run(using: &context)
        } else if let `default` = self.defaultCommand {
            return try `default`.run(using: &context)
        } else {
            try self.outputHelp(using: &context)
            throw CommandError.missingCommand
        }
    }

    private func commmand(using context: inout CommandContext) throws -> AnyCommand? {
        if let name = context.input.arguments.first {
            context.input.arguments.removeFirst()
            guard let command = self.commands[name] else {
                throw CommandError.unknownCommand(name, available: Array(self.commands.keys))
            }
            // executable should include all subcommands
            // to get to the desired command
            context.input.executablePath.append(name)
            return command
        } else {
            return nil
        }
    }


    private func outputFrameworkVersion(context: CommandContext) {
        do {
            let packageString = try Process.shell.run("cat", "Package.resolved")
            let package = try JSONDecoder().decode(PackageResolved.self, from: .init(packageString.utf8))
            if let vapor = package.object.pins.filter({ $0.package == "vapor" }).first {
                context.console.output(key: "framework", value: vapor.state.version)
            } else {
                context.console.output("\("note:", style: .warning) this Swift project does not depend on Vapor.")
                context.console.output(key: "framework", value: "vapor framework for this project: this Swift project does not depend on Vapor. Please ensure you are in a Vapor project directory. If you are, ensure you have built the project with `swift build`. You can create a new project with `vapor new MyProject`")
            }
        } catch {
            context.console.output("\("note:", style: .warning) no Package.resolved file was found. Possibly not currently in a Swift package directory")
            context.console.output(key: "framework", value: "vapor framework for this project: no Package.resolved file found. Please ensure you are in a Vapor project directory. If you are, ensure you have built the project with `swift build`. You can create a new project with `vapor new MyProject`")
        }
    }

    private func outputToolboxVersion(context: CommandContext) {
        do {
            if let version = staticVersion {
                // compiled with static version, use that
                context.console.output(key: "toolbox", value: version)
            } else {
                // determine version through homebrew
                let brewString = try Process.shell.run("brew", "info", "vapor")
                let versionFinder = try NSRegularExpression(pattern: #"(\d+\.)(\d+\.)(\d)"#)
                let versionString = String(brewString.split(separator: "\n")[0])
                if let match = versionFinder.firstMatch(in: versionString, options: [], range: .init(location: 0, length: versionString.utf16.count)) {
                    let version = versionString[Range(match.range, in: versionString)!]
                    context.console.output(key: "toolbox", value: "\(version)")
                } else {
                    context.console.output(key: "toolbox", value: versionString)
                }
            }
        } catch {
            context.console.output("\("note:", style: .warning) could not determine toolbox version.")
            context.console.output(key: "toolbox", value: "not found")
        }
    }
}

private struct PackageResolved: Codable {
    struct Object: Codable {
        struct Pin: Codable {
            struct State: Codable {
                var version: String
            }
            var package: String
            var state: State
        }
        var pins: [Pin]
    }
    var object: Object
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
        try console.run(Toolbox(), input: input)
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
