import ArgumentParser
import Foundation
import Synchronization
import Yams

@main
struct Vapor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Vapor Toolbox (Server-side Swift web framework)",
        version: Self.version,
        subcommands: [New.self],
        defaultSubcommand: New.self
    )

    nonisolated(unsafe) static var manifest: TemplateManifest? = nil
    static let templateURL: URL = FileManager.default.temporaryDirectory.appending(path: ".vapor-template", directoryHint: .isDirectory)
    static let gitURL = try! Process.shell.which("git")

    static func main() {
        do {
            try Self.preprocess(CommandLine.arguments)
            var command = try parseAsRoot(nil)
            try command.run()
        } catch {
            exit(withError: error)
        }
    }

    /// Get the template's `manifest.yml` file, decode it and save it.
    ///
    /// Clones the template repository, decodes the `manifest.yml` file and stores it in the ``Vapor/manifest`` `static` property for later use.
    ///
    /// - Parameter arguments: The command line arguments.
    static func preprocess(_ arguments: [String]) throws {
        let templateWebURL =
            if let index = arguments.firstIndex(of: "--template") {
                arguments[index + 1]
            } else if let index = arguments.firstIndex(of: "-T") {
                arguments[index + 1]
            } else {
                "https://github.com/vapor/template"
            }

        let branch: String? =
            if let index = arguments.firstIndex(of: "--branch") {
                arguments[index + 1]
            } else {
                nil
            }

        try? FileManager.default.removeItem(at: Self.templateURL)

        if !arguments.contains("-h"), !arguments.contains("--help"), !arguments.contains("--version") {
            print("Cloning template...".colored(.cyan))
        }
        var cloneArgs = ["clone"]
        if let branch {
            cloneArgs.append("--branch")
            cloneArgs.append(branch)
        }
        cloneArgs.append(templateWebURL)
        cloneArgs.append(Self.templateURL.path())
        try Process.runUntilExit(Self.gitURL, arguments: cloneArgs)

        let manifestURL = Self.templateURL.appending(path: "manifest.yml")
        if FileManager.default.fileExists(atPath: manifestURL.path()) {
            let yaml = try String(contentsOf: manifestURL, encoding: .utf8)
            Self.manifest = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)
        }
    }

    /// The version of this Vapor Toolbox.
    static var version: String {
        do {
            if let staticVersion {
                // Compiled with static version, use that
                return "toolbox: \(staticVersion.colored(.cyan))"
            } else {
                // Determine version through Homebrew
                let brewString = try Process.shell.brewInfo("vapor")
                let version = /(\d+\.)(\d+\.)(\d)/
                let versionString = brewString.split(separator: "\n")[0]
                if let match = try version.firstMatch(in: versionString) {
                    return "toolbox: " + "\(match.0)".colored(.cyan)
                } else {
                    return "toolbox: \(versionString.colored(.cyan))"
                }
            }
        } catch {
            return "note: ".colored(.yellow) + "could not determine toolbox version." + "\n"
                + "toolbox: " + "not found".colored(.cyan)
        }
    }
}
