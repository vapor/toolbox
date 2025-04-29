import ArgumentParser
import Subprocess
import Yams

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@main
struct Vapor: AsyncParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
        abstract: "Vapor Toolbox (Server-side Swift web framework)",
        subcommands: [New.self],
        defaultSubcommand: New.self
    )

    nonisolated(unsafe) static var manifest: TemplateManifest? = nil
    static let templateURL = URL.temporaryDirectory.appending(path: ".vapor-template", directoryHint: .isDirectory)

    static func main() async {
        do {
            try await Self.preprocess(CommandLine.arguments)
            var command = try parseAsRoot(nil)
            if var asyncCommand = command as? any AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            exit(withError: error)
        }
    }

    /// Get the template's manifest file, decode it and save it.
    ///
    /// Clones the template repository, decodes the manifest file and stores it in the ``Vapor/manifest`` `static` property for later use.
    ///
    /// - Parameter arguments: The command line arguments.
    static func preprocess(_ arguments: [String]) async throws {
        guard !arguments.contains("--version") else {
            Self.configuration.version = await Self.version
            return
        }

        let templateWebURL =
            if let index = arguments.firstIndex(of: "--template") {
                arguments[index + 1]
            } else if let index = arguments.firstIndex(of: "-t") {
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

        if !arguments.contains("-h"),
            !arguments.contains("--help"),
            !arguments.contains("-help"),
            !arguments.contains("--help-hidden"),
            !arguments.contains("-help-hidden"),
            !arguments.contains("--dump-variables")
        {
            print("Cloning template...".colored(.cyan))
        }
        var cloneArgs = ["clone"]
        if let branch {
            cloneArgs.append("--branch")
            cloneArgs.append(branch)
        }
        cloneArgs.append(templateWebURL)
        cloneArgs.append(Self.templateURL.path())
        _ = try await Subprocess.run(.name("git"), arguments: Arguments(cloneArgs))

        var manifestURL: URL
        if let index = arguments.firstIndex(of: "--manifest") {
            manifestURL = Self.templateURL.appending(path: arguments[index + 1])
        } else {
            manifestURL = Self.templateURL.appending(path: "manifest.yml")
            if !FileManager.default.fileExists(atPath: manifestURL.path()) {
                manifestURL = Self.templateURL.appending(path: "manifest.json")
            }
        }

        if FileManager.default.fileExists(atPath: manifestURL.path()) {
            let manifestData = try Data(contentsOf: manifestURL)
            Self.manifest =
                if manifestURL.pathExtension == "json" {
                    try JSONDecoder().decode(TemplateManifest.self, from: manifestData)
                } else {
                    try YAMLDecoder().decode(TemplateManifest.self, from: manifestData)
                }
        }
    }

    /// The version of this Vapor Toolbox.
    static var version: String {
        get async {
            do {
                if let staticVersion {
                    // Compiled with static version, use that
                    return "toolbox: \(staticVersion.colored(.cyan))"
                } else {
                    // Determine version through Homebrew
                    let brewString =
                        try await Subprocess.run(
                            .name("brew"),
                            arguments: ["info", "vapor", "--formula"]
                        ).standardOutput ?? "unknown"
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
}
