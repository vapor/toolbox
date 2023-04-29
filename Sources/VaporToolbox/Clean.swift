import ConsoleKit
import Foundation

/// Cleans temporary files created by Xcode and SPM.
struct Clean: Command {
    struct Signature: CommandSignature {
        @Flag(name: "update", short: "u", help: "Delete Package.resolved file if it exists.")
        var update: Bool
        @Flag(name: "global", short: "g", help: "Clean Xcode's global DerivedData cache.")
        var global: Bool
        @Flag(name: "swiftpm", short: "s", help: "Delete .swiftpm folder.")
        var swiftPM: Bool
    }
    let signature = Signature()
    let help = "Cleans temporary files."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        let cleaner = try Cleaner(ctx: ctx, sig: signature)
        try cleaner.run()
    }
}

class Cleaner {
    let ctx: CommandContext
    let sig: Clean.Signature
    let cwd: String
    let files: [String]

    var operations: [String: CleanResult] = [:]

    init(ctx: CommandContext, sig: Clean.Signature) throws {
        self.ctx = ctx
        self.sig = sig
        self.cwd = FileManager.default.currentDirectoryPath.trailingSlash
        self.files = try FileManager.default.contentsOfDirectory(atPath: self.cwd)
    }

    func run() throws {
        ctx.console.warning("This command is deprecated. Use `swift package clean` instead.")

        var ops: [(String, () throws -> CleanResult)] = []
        ops.append((".build", cleanBuildFolder))
        ops.append(("Package.resolved", cleanPackageResolved))
        ops.append((".swiftpm", cleanSwiftPM))
        #if os(macOS)
        ops.append(("xcodeproj", cleanXcode))
        ops.append(("Local DerivedData", cleanLocalDerived))
        ops.append(("Global DerivedData", cleanGlobalDerived))
        #endif

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

    private func cleanSwiftPM() throws -> CleanResult {
        guard self.sig.swiftPM else {
            return .ignored("Use [--swiftpm,-s] flag to remove this folder during clean.")
        }
        guard files.contains(".swiftpm") else {
            return .notNecessary
        }
        try FileManager.default.removeItem(atPath: self.cwd.appendingPathComponents(".swiftpm"))
        return .success
    }


    private func cleanPackageResolved() throws -> CleanResult {
        guard files.contains("Package.resolved") else { return .notNecessary }
        if sig.update {
            try FileManager.default.removeItem(atPath: self.cwd.appendingPathComponents("Package.resolved"))
            return .success
        } else {
            return .ignored("Use [--update,-u] flag to remove this file during clean.")
        }
    }

    private func cleanBuildFolder() throws -> CleanResult {
        guard files.contains(".build") else { return .notNecessary }
        try FileManager.default.removeItem(atPath: self.cwd.appendingPathComponents(".build"))
        return .success
    }

    private func cleanXcode() throws -> CleanResult {
        guard files.contains(where: { $0.hasSuffix(".xcodeproj") }) else { return .notNecessary }
        try files.filter { $0.hasSuffix(".xcodeproj") }.forEach { try FileManager.default.removeItem(atPath: self.cwd.appendingPathComponents($0)) }
        return .success
    }

    private func cleanLocalDerived() throws -> CleanResult {
        let didCleanRelativeLocation = try cleanRelativeDerivedDataLocation()
        if didCleanRelativeLocation {
            return .success
        } else {
            return .notNecessary
        }
    }

    private func cleanGlobalDerived() throws -> CleanResult {
        if self.sig.global {
            let didCleanDefaultLocation = try cleanDefaultDerivedDataLocation()
            if didCleanDefaultLocation {
                return .success
            } else {
                return .notNecessary
            }
        } else {
            return .ignored("Use [--global,-g] flag to clean all DerivedData caches.")
        }
    }

    private func cleanDefaultDerivedDataLocation() throws -> Bool {
        let defaultLocation = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path.appendingPathComponents("Developer", "Xcode", "DerivedData")
        guard
            FileManager.default.fileExists(atPath: defaultLocation)
            else { return false }
        try FileManager.default.removeItem(atPath: defaultLocation)
        return true
    }

    private func cleanRelativeDerivedDataLocation() throws -> Bool {
        let relativePath = cwd.appendingPathComponents("DerivedData")
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
            return "Something went wrong."
        case .success:
            return "Removed."
        case .notNecessary:
            return "Nothing to clean."
        case .ignored(let msg):
            return msg.consoleText()
        }
    }
}
