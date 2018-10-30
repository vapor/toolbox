import Vapor
import Cloud

/// Creates an Application to run.
public func boot() -> Future<Application> {
    var services = Services.default()

    var commands = CommandConfig()
//    commands.use(XcodeCommand(), as: "xcode")
    commands.use(CleanCommand(), as: "clean")
    commands.use(GenerateLinuxMain(), as: "linux-main")
    commands.use(Test(), as: "test")
    commands.use(Cloud.CloudGroup(), as: "cloud")
    services.register(commands)

    return Application.asyncBoot(services: services)
}
