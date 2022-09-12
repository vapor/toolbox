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
            func missingVaporOutput() {
                context.console.output("\("note:", style: .warning) this Swift project does not depend on Vapor.")
                context.console.output(key: "framework", value: "Vapor framework for this project: this Swift project does not depend on Vapor. Please ensure you are in a Vapor project directory. If you are, ensure you have built the project with `swift build`. You can create a new project with `vapor new MyProject`")
            }
            
            let packageString = try Process.shell.run("cat", "Package.resolved")
            let data = Data(packageString.utf8)
            let version = try JSONDecoder().decode(Version.self, from: data)
            switch version.version {
            case PackageResolvedV1.version:
                let v1 = try JSONDecoder().decode(PackageResolvedV1.self, from: data)
                if let vapor = v1.object.pins.first(where: { $0.package == "vapor" }) {
                    if let version = vapor.state.version {
                        context.console.output(key: "framework", value: version)
                    } else if let branch = vapor.state.branch {
                        context.console.output(key: "framework", value: "Branch-\(branch) Unknown version")
                    } else  {
                        context.console.output(key: "framework", value: "Revision-\(vapor.state.revision) Unknown version")
                    }
                } else {
                    missingVaporOutput()
                }
            case PackageResolvedV2.version:
                let v2 = try JSONDecoder().decode(PackageResolvedV2.self, from: data)
                if let vapor = v2.pins.first(where: { $0.identity == "vapor" }) {
                    if let version = vapor.state.version {
                        context.console.output(key: "framework", value: version)
                    } else if let branch = vapor.state.branch {
                        context.console.output(key: "framework", value: "Branch-\(branch) Unknown version")
                    } else if let revision = vapor.state.revision {
                        context.console.output(key: "framework", value: "Revision-\(revision) Unknown version")
                    } else {
                        context.console.output(key: "framework", value: "Unknown version")
                    }
                } else {
                    missingVaporOutput()
                }
            default:
                context.console.output(key: "framework", value: "Unsupported Package.resolved version")
            }
        } catch {
            context.console.output("\("note:", style: .warning) no Package.resolved file was found. Possibly not currently in a Swift package directory")
            context.console.output(key: "framework", value: "Vapor framework for this project: no Package.resolved file found. Please ensure you are in a Vapor project directory. If you are, ensure you have built the project with `swift build`. You can create a new project with `vapor new MyProject`")
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

private struct Version: Codable {
    let version: Int
}
    
private struct PackageResolvedV1: Codable {
    static let version = 1
    struct Object: Codable {
        struct Pin: Codable {
            struct State: Codable {
                let revision: String
                let branch: String?
                let version: String?
            }
            let package: String?
            let state: State
        }
        let pins: [Pin]
    }
    let object: Object
    let version: Int
}

private struct PackageResolvedV2: Codable {
    static let version = 2
    struct Pin: Codable {
        struct State: Codable {
            let branch: String?
            let revision: String?
            let version: String?
        }
        let identity: String
        let state: State
    }

    let pins: [Pin]
    let version: Int
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
