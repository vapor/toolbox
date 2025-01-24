import ArgumentParser
import Foundation
import Synchronization
import Yams

struct Vapor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Vapor Toolbox (Server-side Swift web framework)",
        version: "19.0.0",
        subcommands: [New.self],
        defaultSubcommand: New.self
    )

    nonisolated(unsafe) static var manifest: TemplateManifest? = nil
    static let templateURL: URL = FileManager.default.temporaryDirectory.appending(path: ".vapor-template", directoryHint: .isDirectory)
    static let gitURL = URL(filePath: try! Process.shell.which("git"))

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
}
