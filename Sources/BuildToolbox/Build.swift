import Foundation
import Subprocess

@main
struct Build {
    static func main() async {
        do {
            try await Self.withVersion(in: "Sources/VaporToolbox/Version.swift", as: Self.currentVersion) {
                _ = try await Subprocess.run(
                    .name("swift"),
                    arguments: [
                        "build",
                        "--disable-sandbox",
                        "--configuration", "release",
                        "-Xswiftc", "-cross-module-optimization",
                    ],
                    output: .discarded
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
            .replacing("nil", with: "\"\(version)\"")
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
            let tag = try await Subprocess.run(
                .name("git"),
                arguments: ["describe", "--tags", "--exact-match"],
                output: .string(limit: 4096)
            ).standardOutput
            if !tag.isEmpty {
                return tag.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            async let branchSubprocess = Subprocess.run(
                .name("git"),
                arguments: ["symbolic-ref", "-q", "--short", "HEAD"],
                output: .string(limit: 4096)
            )
            async let commitSubprocess = Subprocess.run(
                .name("git"),
                arguments: ["rev-parse", "--short", "HEAD"],
                output: .string(limit: 4096)
            )
            let (branch, commit) = try await (branchSubprocess.standardOutput, commitSubprocess.standardOutput)
            if !branch.isEmpty, !commit.isEmpty {
                return
                    "\(branch.trimmingCharacters(in: .whitespacesAndNewlines)) (\(commit.trimmingCharacters(in: .whitespacesAndNewlines)))"
            }

            return "unknown"
        }
    }
}
