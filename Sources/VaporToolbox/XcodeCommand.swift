import Vapor
import Globals

// TODO: Xcode Additions
// automatically add xcconfig
// swift package generate-xcodeproj --xcconfig-overrides Sandbox.xcconfig
//
// automatically add environment variables to project file, more work,
// but would be nice
//

// Generates an Xcode project
struct XcodeCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Generates Xcode projects for SPM packages."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        ctx.console.output("Generating Xcodeproj...")
        let generateProcess = Process.asyncExecute(
            "swift",
            ["package", "generate-xcodeproj"],
            on: ctx.container
        ) { output in
            switch output {
            case .stderr(let err):
                let str = String(bytes: err, encoding: .utf8) ?? "error"
                ctx.console.output("Error:", style: .error, newLine: true)
                ctx.console.output(str, style: .error, newLine: false)
            case .stdout(let out):
                let str = String(bytes: out, encoding: .utf8) ?? ""
                ctx.console.output(str.consoleText(), newLine: false)
            }
        }

        return generateProcess.map { val in
            if val == 0 {
                ctx.console.output(
                    "Generated Xcodeproj.",
                    style: .info,
                    newLine: true
                )
                try Shell.bash("open *.xcodeproj")
            } else {
                ctx.console.output(
                    "Failed to generate Xcodeproj.",
                    style: .error,
                    newLine: true
                )
            }
        }
    }
}
