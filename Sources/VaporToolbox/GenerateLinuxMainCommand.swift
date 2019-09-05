import ConsoleKit
import Globals
import LinuxTestsGeneration

//extension Option where Value == String {
//    static let ignoredDirectories: Option = .init(
//        name: "ignored-directories",
//        short: "i",
//        type: .value,
//        help: "use this to ignore a tests directory."
//    )
//}

/// Cleans temporary files created by Xcode and SPM.
struct GenerateLinuxMain: Command {
    struct Signature: CommandSignature {
        @Option(name: "ignored-directories", short: "i", help: "the test directories to ignore when generating, ie: '-i foo,internal,local'")
        var ignoredDirectories: String
    }
    let signature = Signature()
    
    let help = "generates LinuxMain.swift file."

    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let ignoredDirectories = signature.ignoredDirectories?.components(separatedBy: ",") ?? []
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
