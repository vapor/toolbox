import ConsoleKit
import Globals
import Foundation

extension Option where Value == Bool {
    static var update: Option = .init(name: "update", short: "u", type: .flag, help: "cleans Package.resolved file if it exists.")
    static var keepCheckouts: Option = .init(name: "keep-checkouts", short: "k", type: .flag, help: "keep checkouts ")
}
/// Cleans temporary files created by Xcode and SPM.
struct CleanCommand: Command {
    struct Signature: CommandSignature {
        let update: Option = .update
        let keepCheckouts: Option = .keepCheckouts
    }
    let signature = Signature()
    let help = "cleans temporary files."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let cleaner = try Cleaner(ctx: ctx)
        try cleaner.run()
    }
}

class Cleaner<C: CommandRunnable> {
    let ctx: CommandContext<C>
    let cwd: String
    let files: String

    var operations: [String: CleanResult] = [:]

    init(ctx: CommandContext<C>) throws {
        self.ctx = ctx
        let cwd = try Shell.cwd()
        self.cwd = cwd.trailingSlash
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

        let rows = ops.map { (name, op) -> [ConsoleText] in
            var row = [ConsoleText]()
            do {
                let result = try op()
                row.append(name.consoleText(result.style))
                row.append(result.report)
            } catch {
                row.append(name.consoleText(CleanResult.failure.style))
                row.append(error.localizedDescription.consoleText())
            }
            return row
        }
        
        
        let drawer = TableDrawer(rows: rows)
        let text = drawer.drawTable()
        ctx.console.output(text, newLine: false)
    }

    private func cleanPackageResolved() throws -> CleanResult {
        guard files.contains("Package.resolved") else { return .notNecessary }
        if ctx.flag(.update) {
            try Shell.delete("Package.resolved")
            return .success
        } else {
            return .ignored("use [--update,-u] flag to remove this file during clean")
        }
    }

    private func cleanBuildFolder() throws -> CleanResult {
        guard files.contains(".build") else { return .notNecessary }
        var list = try Shell.allFiles(in: ".build").split(separator: "\n")
        if ctx.flag(.keepCheckouts) {
            list.removeAll(where: ["checkouts", ".", ".."].contains)
            try list.map { ".build/" + $0 } .forEach(Shell.delete)
        } else {
            try Shell.delete(".build")
        }
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
            .trailingSlash
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
