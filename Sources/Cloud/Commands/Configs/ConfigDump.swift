import Foundation
import Core

public final class ConfigDump: Command {
    public let id = "dump"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The application to which the environment belongs"
        ]),
        Option(name: "env", help: [
            "The environment for which configs will be modified"
        ]),
    ]
    
    public let help: [String] = [
        "Dumps config information for the selected environment"
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
        
        let configs = try console.loadingBar(title: "Loading configs", ephemeral: true) {
            return try cloud.configurations(
                for: .model(env),
                in: .model(app)
            )
        }
        
        
        if configs.isEmpty {
            console.warning("No configs")
            console.detail("Create configs", "vapor cloud config create")
        }
        
        for config in configs {
            console.detail(config.key, config.value)
        }
    }
}
