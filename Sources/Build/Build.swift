import Subprocess

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@main
struct Build {
    static func main() async {
        do {
            try await Self.withVersion(in: "Sources/VaporToolbox/Version.swift", as: Self.currentVersion) {
                _ = try await Subprocess.run(
                    .path("/usr/bin/env"),
                    arguments: [
                        "swift", "build",
                        "--disable-sandbox",
                        "--configuration", "release",
                        "-Xswiftc", "-cross-module-optimization",
                    ]
                )
            }
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    static func withVersion(in file: String, as version: String, _ operation: @Sendable () async throws -> Void) async throws {
        let fileURL = URL(filePath: file)
        let originalFileContents = try String(contentsOf: fileURL, encoding: .utf8)

        try originalFileContents
            .replacingOccurrences(of: "nil", with: "\"\(version)\"")
            .write(to: fileURL, atomically: true, encoding: .utf8)

        do {
            try await operation()
        } catch {
            // Revert the file change
            try? originalFileContents.write(to: fileURL, atomically: true, encoding: .utf8)
            throw error
        }
    }

    static var currentVersion: String {
        get async throws {
            let tagResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "describe", "--tags", "--exact-match"])
            if let tag = tagResult.standardOutput, !tag.isEmpty {
                return tag.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let branchResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "symbolic-ref", "-q", "--short", "HEAD"])
            let commitResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "rev-parse", "--short", "HEAD"])
            if let branch = branchResult.standardOutput, !branch.isEmpty,
                let commit = commitResult.standardOutput, !commit.isEmpty
            {
                return
                    "\(branch.trimmingCharacters(in: .whitespacesAndNewlines)) (\(commit.trimmingCharacters(in: .whitespacesAndNewlines)))"
            }

            return "unknown"
        }
    }
}
