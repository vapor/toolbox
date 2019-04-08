import Vapor
import CloudCommands
import Globals

/// Creates an Application to run.
public func boot() -> Application {
    var services = Services.default()

    var commands = CommandConfig()
    commands.use(CleanCommand(), as: "clean")
    commands.use(GenerateLinuxMain(), as: "linux-main")
    commands.use(CloudCommands.CloudGroup(), as: "cloud")
    commands.use(New(), as: "new")
    commands.use(PrintDroplet(), as: "drop")

    // for running quick exec tests
    commands.use(Test(), as: "test")
    commands.use(XcodeCommand(), as: "xcode")
    commands.use(LeafGroup(), as: "leaf")
//    commands.use(LeafXcodeCommand(), as: "leaf")
//    commands.use(LoadLeafPackage(), as: "info")

    services.register(CommandConfig.self, { _ in commands })

    
    return Application(configure: { services })
}
