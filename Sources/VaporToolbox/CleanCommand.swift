import Vapor

/// Cleans temporary files created by Xcode and SPM.
struct CleanCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .flag(name: "update", short: "u", help: [
            "Cleans the Package.resolved file if it exists",
            "This is equivalent to doing `swift package update`"
        ])
    ]

    /// See `Command`.
    var help: [String] = ["Cleans temporary files."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        drawTable(with: ctx)
        return .done(on: ctx.container)
    }

    func _run(using ctx: CommandContext) throws -> Future<Void> {

        var cleaned = false

        // TODO: !
        let cwd = try Shell.cwd()
        let files = try Shell.allFiles(in: cwd)
        #if os(macOS)
        if files.contains(".xcodeproj") {
            try Shell.delete("*.xcodeproj")
            ctx.console.output("cleaned: ".consoleText(.success) + ".xcodeproj")
            cleaned = true
            let derivedData = cwd.finished(with: "/").appending("DerivedData")
            if !FileManager.default.fileExists(atPath: derivedData) {
                ctx.console.output("warning: ".consoleText(.warning) + "no ./DerivedData folder detected")
                ctx.console.output("         enable relative derived data in Xcode > Preferences > Locations")
            } else {
                do {
                    // TODO: Check gitignore for DerivedData
                    try Shell.delete("DerivedData")
                    ctx.console.output("cleaned: ".consoleText(.success) + "DerivedData")
                } catch {
                    ctx.console.output("error: ".consoleText(.error) + "could not clean DerivedData")
                    ctx.console.output("       make sure Xcode is closed before running clean")
                }
            }
        }
        #endif

        if files.contains(".build") {
            try Shell.delete(".build")
            ctx.console.output("cleaned: ".consoleText(.success) + ".build")
            cleaned = true
        }
        if files.contains("Package.resolved") {
            if ctx.options["update"]?.bool == true {
                try Shell.delete("Package.resolved")
                ctx.console.output("cleaned: ".consoleText(.success) + "Package.resolved")
                cleaned = true
            } else {
                ctx.console.output("info: ".consoleText(.info) + "Package.resolved file detected")
                ctx.console.output("      use [--update,-u] flag to remove this file during clean")
            }
        }

        if !cleaned {
            ctx.console.output("info: ".consoleText(.info) + "nothing to clean")
        }
        return .done(on: ctx.container)
    }
}
