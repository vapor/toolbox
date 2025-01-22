import ArgumentParser
import Foundation
import Synchronization
import Yams

struct Vapor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Vapor Toolbox (Server-side Swift web framework)",
        subcommands: [New.self],
        defaultSubcommand: New.self
    )

    static let manifest = Mutex<TemplateManifest?>(nil)

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

        let templateURL = FileManager.default.temporaryDirectory.appending(path: ".vapor-template", directoryHint: .isDirectory)
        let gitURL = URL(filePath: try Process.shell.which("git"))

        var cloneArgs = ["clone"]
        if let branch {
            cloneArgs.append("--branch")
            cloneArgs.append(branch)
        }
        cloneArgs.append(templateWebURL)
        cloneArgs.append(templateURL.path())
        try Process.runUntilExit(gitURL, arguments: cloneArgs)

        if FileManager.default.fileExists(atPath: templateURL.appending(path: "manifest.yml").path()) {
            defer { try? FileManager.default.removeItem(at: templateURL) }
            let yaml = try String(contentsOf: templateURL.appending(path: "manifest.yml"), encoding: .utf8)
            try Vapor.manifest.withLock {
                $0 = try YAMLDecoder().decode(TemplateManifest.self, from: yaml)
            }
        }
    }
}
