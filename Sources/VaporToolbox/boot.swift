import Vapor
import CloudCommands

/// Creates an Application to run.
public func boot() -> Future<Application> {
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
    commands.use(LeafXcodeCommand(), as: "leaf")
    services.register(commands)

    return Application.asyncBoot(services: services)
}
