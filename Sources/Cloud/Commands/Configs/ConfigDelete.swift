import Foundation
import Core

public final class ConfigDelete: Command {
    public let id = "delete"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The application to which the environment belongs"
        ]),
        Option(name: "env", help: [
            "The environment for which configs will be modified"
        ]),
        Option(name: "all", help: [
            "If true, all config keys will be deleted"
        ])
    ]
    
    public let help: [String] = [
        "Deletes configs for the selected environment.",
        "Pass keys as space-separated values.",
        "ex: vapor cloud config delete FOO HELLO"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try cloud.application(for: arguments, using: console)
        let env = try cloud.environment(on: .model(app), for: arguments, using: console)
        
        let configs: [Configuration] = arguments.flatMap { arg in
            return arg.hasPrefix("--") ? nil : arg
        }.dropFirst(2).array.map { config in
            return Configuration(
                id: nil,
                environment: .model(env),
                key: config,
                value: ""
            )
        }
        
        if arguments.option("all")?.bool == true {
            guard console.confirm("Are you sure you want to delete all keys?", style: .warning) else {
                throw "Cancelled"
            }
        } else {
            guard configs.count >= 1 else {
                console.warning("No keys supplied")
                console.info("Pass keys as space-separated values.")
                console.info("ex: vapor cloud config delete FOO HELLO")
                console.info("You may also use --all to delete all keys")
                throw "Keys required"
            }
            
            configs.forEach { config in
                console.error(config.key)
            }
            
            try console.verifyAboveCorrect()
        }
        
        _ = try console.loadingBar(title: "Deleting configs") {
            if configs.count == 0 {
                _ = try cloud.replace(configs, for: .model(env), in: .model(app))
            } else {
                _ = try cloud.delete(configs, for: .model(env), in: .model(app))
            }
        }
    }
}
