import Subprocess

func main() async {
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
}

func withVersion(in file: String, as version: String, _ operation: () async throws -> Void) async throws {
    let fileURL = URL(fileURLWithPath: file)
    let originalFileContents = try String(contentsOf: fileURL, encoding: .utf8)

    try originalFileContents
        .replacingOccurrences(of: "nil", with: "\"\(version)\"")
        .write(to: fileURL, atomically: true, encoding: .utf8)

    var operationError: Error?
    do {
        try await operation()
    } catch {
        operationError = error
    }

    // If an error occurred, revert the file change
    if operationError != nil {
        try? originalFileContents
            .write(to: fileURL, atomically: true, encoding: .utf8)
        if let error = operationError {
            throw error
        }
    }
}

var currentVersion: String {
    get async throws {
        do {
            let tag = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "describe", "--tags", "--exact-match"])
            return tag
        } catch {
            let branch = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "symbolic-ref", "-q", "--short", "HEAD"])
            let commit = try await Subprocess.run(.path("/usr/bin/env"), arguments: ["git", "rev-parse", "--short", "HEAD"])
            return "\(branch) (\(commit))"
        }
    }
}

await main()
