import Foundation
import Core

public final class ConfigModify: Command {
    public let id = "modify"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The application to which the environment belongs"
        ]),
        Option(name: "env", help: [
            "The environment for which configs will be modified"
        ]),
        Option(name: "replace", help: [
            "If true, configurations will be replaced",
            "(instead of updated) with the supplied values.",
            "This means any keys not present in the update",
            "will be deleted."
        ])
    ]
    
    public let help: [String] = [
        "Modifies configs for the selected environment.",
        "Pass configs as space-separated KEY=VALUE pairs.",
        "ex: vapor cloud config modify FOO=BAR HELLO=WORLD"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        var arguments = arguments
        if let index = arguments.index(of: "-y") {
            arguments.remove(at: index)
        }
        if let index = arguments.index(of: "-n") {
            arguments.remove(at: index)
        }
        
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        
        let configs: [Configuration] = try arguments.flatMap { arg in
                return arg.hasPrefix("--") ? nil : arg
        }.dropFirst(2).array.map { config in
            let parts = config.characters.split(separator: "=")
            guard parts.count == 2 else {
                throw "Invalid config '\(config)'. Format must be KEY=VALUE."
            }
            
            return Configuration(
                id: nil,
                environment: .model(env),
                key: String(parts[0]),
                value: String(parts[1])
            )
        }
        
        guard configs.count >= 1 else {
            console.warning("No configs supplied")
            console.info("Pass configs as space-separated KEY=VALUE pairs.")
            console.info("ex: vapor cloud config modify FOO=BAR HELLO=WORLD")
            throw "Configs required"
        }
        
        configs.forEach { config in
            console.detail(config.key, config.value)
        }
        
        try console.verifyAboveCorrect()
        
        let replace: Bool
        if arguments.option("replace")?.bool == true {
            console.warning("Any keys not present in this modification")
            console.warning("will be deleted.")
            guard console.confirm("Are you sure you want to replace?") else {
                throw "Cancelled"
            }
            replace = true
        } else {
            replace = false
        }
        
        _ = try console.loadingBar(title: "Updating configs") {
            if replace {
                _ = try cloud.replace(
                    configs,
                    for: .model(env),
                    in: .model(app)
                )
            } else {
                _ = try cloud.update(
                    configs,
                    for: .model(env),
                    in: .model(app)
                )
            }
        }
    }
}
