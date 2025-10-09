import ArgumentParser
import Foundation
import Yams

@main
struct Vapor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Vapor Toolbox (Server-side Swift web framework)",
        version: Self.version,
        subcommands: [New.self],
        defaultSubcommand: New.self
    )

    static let templateURL = URL.homeDirectory.appending(path: ".vapor-template", directoryHint: .isDirectory)
    nonisolated(unsafe) public static var manifest: TemplateManifest? = nil

    static func main() {
        do {
            try loadManifest()
            var command = try parseAsRoot(nil)
            try command.run()
        } catch {
            exit(withError: error)
        }
    }

    static func loadManifest() throws {
        let manifestURL = templateURL.appending(path: "manifest.yml")

        var result: TemplateManifest? = nil

        if FileManager.default.fileExists(atPath: manifestURL.path()) {
            let manifestData = try Data(contentsOf: manifestURL)
            result =
                if manifestURL.pathExtension == "json" {
                    try JSONDecoder().decode(TemplateManifest.self, from: manifestData)
                } else {
                    try YAMLDecoder().decode(TemplateManifest.self, from: manifestData)
                }
        }
        Vapor.manifest = result
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
