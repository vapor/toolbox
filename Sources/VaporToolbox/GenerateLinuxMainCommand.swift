import Vapor
import Globals
import LinuxTestsGeneration

/// Cleans temporary files created by Xcode and SPM.
struct GenerateLinuxMain: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .value(name: "ignored-directories", short: "i", help: [
            "use this to ignore a tests directory"
        ])
    ]

    /// See `Command`.
    var help: [String] = ["Generates LinuxMain.swift file"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let ignoredDirectories = ctx.options["ignored-directories"]?.components(separatedBy: ",") ?? []
        let cwd = try Shell.cwd()
        let testsDirectory = cwd.finished(with: "/") + "Tests"
        ctx.console.output("Building Tests/LinuxMain.swift..")
        let linuxMain = try LinuxMain(
            testsDirectory: testsDirectory,
            ignoring: ignoredDirectories
        )
        ctx.console.output("Writing Tests/LinuxMain.swift..")
        try linuxMain.write()
        ctx.console.success("Generated Tests/LinuxMain.swift.")
        return ctx.done
    }
}
