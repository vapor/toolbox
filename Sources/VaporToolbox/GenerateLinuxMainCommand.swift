import ConsoleKit
import Globals
import LinuxTestsGeneration

extension Option where Value == String {
    static let ignoredDirectories: Option = .init(
        name: "ignored-directories",
        short: "i",
        type: .value,
        help: "use this to ignore a tests directory."
    )
}

/// Cleans temporary files created by Xcode and SPM.
struct GenerateLinuxMain: Command {
    struct Signature: CommandSignature {
        let ignoredDirectories: Option = .ignoredDirectories
    }
    let signature = Signature()
    
    let help = "generates LinuxMain.swift file."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let ignoredDirectories = ctx.rawOptions.value(.ignoredDirectories)?.components(separatedBy: ",") ?? []
        let cwd = try Shell.cwd()
        let testsDirectory = cwd.trailingSlash + "Tests"
        ctx.console.output("building Tests/LinuxMain.swift..")
        let linuxMain = try LinuxMain(
            testsDirectory: testsDirectory,
            ignoring: ignoredDirectories
        )
        ctx.console.output("writing Tests/LinuxMain.swift..")
        try linuxMain.write()
        ctx.console.success("generated Tests/LinuxMain.swift.")
    }
}
