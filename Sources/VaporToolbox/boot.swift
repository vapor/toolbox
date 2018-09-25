import Vapor

/// Creates an Application to run.
public func boot() -> Future<Application> {
    var services = Services.default()

    var commands = CommandConfig()
//    commands.use(XcodeCommand(), as: "xcode")
    commands.use(CleanCommand(), as: "clean")
    commands.use(AltCleanCommand(), as: "alt-clean")
    services.register(commands)

    return Application.asyncBoot(services: services)
}
