import Vapor

/// Cleans temporary files created by Xcode and SPM.
struct AltCleanCommand: Command {
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
        var cleaned = false

        // TODO: !
        let cwd = try Shell.cwd()
        let files = try Shell.allFiles(in: cwd)
        var _cleaned: [String: Bool] = [:]
        if files.contains(".xcodeproj") {

        }
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

    private func cleanXcode() throws -> OperationResult {

    }
}

class Cleaner {
    let ctx: CommandContext
    let cwd: String
    let files: String

    var operations: [String: OperationResult] = [:]

    init(ctx: CommandContext) throws {
        self.ctx = ctx
        let cwd = try Shell.cwd()
        self.cwd = cwd
        self.files = try Shell.allFiles(in: cwd)
    }

    func run() throws {

    }

    private func cleanXcode() throws -> OperationResult {
        guard files.contains(".xcodeproj") else { return .notNecessary }
        try Shell.delete("*.xcodeproj")
        return .succeeded
    }

    // TODO: If found DerivedData at least once, assume relative enabled
    private func cleanDerived() throws -> OperationResult {
        let derivedData = cwd.finished(with: "/").appending("DerivedData")
        // if exists, delete
        if !FileManager.default.fileExists(atPath: derivedData) {
            // TODO: Check gitignore for DerivedData
            ctx.console.output("warning: ".consoleText(.warning) + "no ./DerivedData folder detected")
            ctx.console.output("         enable relative derived data in Xcode > Preferences > Locations > Derived Data")
            ctx.console.output("set to: " + "Relative".consoleText(.success))
        } else {
            do {
                try Shell.delete("DerivedData")
                ctx.console.output("cleaned: ".consoleText(.success) + "DerivedData")
            } catch {
                ctx.console.output("error: ".consoleText(.error) + "could not clean DerivedData")
                ctx.console.output("       make sure Xcode is closed before running clean")
            }
        }

        fatalError()
    }

    private func informDerivedData() throws {
        ctx.console.output("warning: ".consoleText(.warning) + "no ./DerivedData folder detected")
        ctx.console.output("         enable relative derived data in Xcode > Preferences > Locations > Derived Data")
        ctx.console.output("set to: " + "Relative".consoleText(.success))
        ctx.console.output("ensure text box is set to: " + "DerivedData".consoleText(.success))

        let gitignore = try Shell.readFile(path: ".gitignore")
        guard !gitignore.contains("DerivedData") else { return }
        ctx.console.output("")
        ctx.console.output("warning: ".consoleText(.warning) + "Please add DerivedData to your .gitignore")
        ctx.console.output("or it will be tracked by .git after making this change.")

        guard ctx.console.confirm("Would you like me to do this now?") else { return }
        
    }
}

enum OperationResult {
    case failed, succeeded, notNecessary
}
