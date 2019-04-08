import Vapor
import Globals

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
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let cleaner = try Cleaner(ctx: ctx)
        try cleaner.run()
        return ctx.done
    }
}

class Cleaner {
    let ctx: CommandContext
    let cwd: String
    let files: String

    var operations: [String: CleanResult] = [:]

    init(ctx: CommandContext) throws {
        self.ctx = ctx
        let cwd = try Shell.cwd()
        self.cwd = cwd.finished(with: "/")
        self.files = try Shell.allFiles(in: cwd)
    }

    func run() throws {
        var ops: [(String, () throws -> CleanResult)] = []
        #if os(macOS)
        ops.append(("DerivedData", cleanDerived))
        ops.append(("xcodeproj", cleanXcode))
        #endif
        ops.append((".build", cleanBuildFolder))
        ops.append(("Package.resolved", cleanPackageResolved))

        for (name, op) in ops {
            do {
                let result = try op()
                let text = name.consoleText(result.style) + ": " + result.report
                ctx.console.output(text)
            } catch {
                let text = name.consoleText(CleanResult.failure.style)
                    + ": "
                    + error.localizedDescription.consoleText()
                ctx.console.output(text)
            }
        }
    }

    private func cleanPackageResolved() throws -> CleanResult {
        guard files.contains("Package.resolved") else { return .notNecessary }
        todo()
//        if ctx.options["update"]?.bool == true {
//            try Shell.delete("Package.resolved")
//            return .success
//        } else {
//            return .ignored("use [--update,-u] flag to remove this file during clean")
//        }
    }

    private func cleanBuildFolder() throws -> CleanResult {
        guard files.contains(".build") else { return .notNecessary }
        try Shell.delete(".build")
        return .success
    }

    private func cleanXcode() throws -> CleanResult {
        guard files.contains(".xcodeproj") else { return .notNecessary }
        try Shell.delete("*.xcodeproj")
        return .success
    }

    private func cleanDerived() throws -> CleanResult {
        let didCleanDefaultLocation = try cleanDefaultDerivedDataLocation()
        if didCleanDefaultLocation { return .success }

        let didCleanRelativeLocation = try cleanRelativeDerivedDataLocation()
        if didCleanRelativeLocation { return .success }

        guard files.contains(".xcodeproj") else { return .notNecessary }
        let derivedLocation = try XcodeBuild.derivedDataLocation()
        guard FileManager.default.fileExists(atPath: derivedLocation) else {
            return .notNecessary
        }
        try FileManager.default.removeItem(atPath: derivedLocation)
        return .success
    }

    private func cleanDefaultDerivedDataLocation() throws -> Bool {
        let defaultLocation = try Shell.homeDirectory()
            .finished(with: "/")
            + "Library/Developer/Xcode/DerivedData"
        guard
            FileManager.default.fileExists(atPath: defaultLocation)
            else { return false }
        try FileManager.default.removeItem(atPath: defaultLocation)
        return true
    }

    private func cleanRelativeDerivedDataLocation() throws -> Bool {
        let relativePath = cwd + "DerivedData"
        guard
            FileManager.default.fileExists(atPath: relativePath)
            else { return false }
        try FileManager.default.removeItem(atPath: relativePath)
        return true
    }
}

enum CleanResult {
    case failure, success, notNecessary, ignored(String)

    var style: ConsoleStyle {
        switch self {
        case .failure:
            return .init(color: .red)
        case .success:
            return .init(color: .green)
        case .notNecessary:
            return .init(color: .cyan)
        case .ignored(_):
            return .init(color: .yellow)
        }
    }

    var report: ConsoleText {
        switch self {
        case .failure:
            return "something went wrong"
        case .success:
            return "cleaned file"
        case .notNecessary:
            return "nothing to clean"
        case .ignored(let msg):
            return msg.consoleText()
        }
    }
}
