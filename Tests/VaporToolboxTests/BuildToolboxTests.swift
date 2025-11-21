import Testing

@testable import BuildToolbox

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Build Toolbox Tests")
struct BuildToolboxTests {
    @Test("Get Current Version from Git", .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil))
    func currentVersion() async throws {
        let version = try await Build.currentVersion

        let branchAndCommit = /^[a-zA-Z0-9._-]+ \([a-zA-Z0-9]{7}\)$/
        // https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
        let semver =
            /^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/

        #expect(version.contains(branchAndCommit) || version.contains(semver))
    }

    @Test("Update Version.swift File", arguments: [true, false])
    func withVersion(operationThrows: Bool) async throws {
        let file = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "TestingVersion.swift")
        let originalFileContents: String = try String(contentsOf: file, encoding: .utf8)
        let newVersion = "1.0.0"

        try? await Build.withVersion(in: file.path(), as: newVersion) {
            if operationThrows {
                struct TestError: Error {}
                throw TestError()
            }
        }

        let updatedFileContents = try String(contentsOf: file, encoding: .utf8)
        #expect(updatedFileContents.contains(operationThrows ? "nil" : newVersion))

        // Revert the file change
        try originalFileContents
            .replacing("\"\(newVersion)\"", with: "nil")
            .write(to: file, atomically: true, encoding: .utf8)
        let revertedFileContents = try String(contentsOf: file, encoding: .utf8)
        #expect(revertedFileContents == originalFileContents)
    }
}
