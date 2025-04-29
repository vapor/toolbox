import Foundation
import Subprocess

do {
    try await withVersion(in: "Sources/VaporToolbox/Version.swift", as: currentVersion) {
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

func withVersion(in file: String, as version: String, _ operation: () async throws -> Void) async throws {
    let fileURL = URL(fileURLWithPath: file)
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

var currentVersion: String {
    get async throws {
        let tagResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "describe", "--tags", "--exact-match"])
        if let tag = tagResult.standardOutput, !tag.isEmpty {
            return tag
        }

        let branchResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "symbolic-ref", "-q", "--short", "HEAD"])
        let commitResult = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "rev-parse", "--short", "HEAD"])
        if let branch = branchResult.standardOutput, !branch.isEmpty,
            let commit = commitResult.standardOutput, !commit.isEmpty
        {
            return "\(branch) (\(commit))"
        }

        return "unknown"
    }
}
