import Vapor

/// Cleans temporary files created by Xcode and SPM.
struct GenerateLinuxMain: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Generates LinuxMain.swift file"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        let cwd = try Shell.cwd()
        let testsDirectory = cwd.finished(with: "/") + "Tests"
        let linuxMain = try LinuxMain(testsDirectory: testsDirectory)
        try linuxMain.write()
        return .done(on: ctx.container)
    }
}
