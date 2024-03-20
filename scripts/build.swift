#!/usr/bin/env swift
import Foundation

struct ShellError: Error {
    var terminationStatus: Int32
}

func main() async {
    do {
        try await build()
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

func build() async throws {
    let version = try await currentVersion()
    try await withVersion(in: "Sources/VaporToolbox/Version.swift", as: version) {
        try await foregroundShell(
            "swift", "build",
            "--disable-sandbox",
            "--configuration", "release",
            "-Xswiftc", "-cross-module-optimization"
        )
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


func currentVersion() async throws -> String {
    do {
        let tag = try await backgroundShell("git", "describe", "--tags", "--exact-match")
        return tag
    } catch {
        let branch = try await backgroundShell("git", "symbolic-ref", "-q", "--short", "HEAD")
        let commit = try await backgroundShell("git", "rev-parse", "--short", "HEAD")
        return "\(branch) (\(commit))"
    }
}

func foregroundShell(_ args: String...) async throws {
    try await withCheckedThrowingContinuation { continuation in
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = args

        task.terminationHandler = { process in
            if process.terminationStatus == 0 {
                continuation.resume()
            } else {
                continuation.resume(throwing: ShellError(terminationStatus: process.terminationStatus))
            }
        }

        do {
            try task.run()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

@discardableResult
func backgroundShell(_ args: String...) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = args
        let output = Pipe()
        task.standardOutput = output
        task.standardError = Pipe()

        task.terminationHandler = { process in
            guard process.terminationStatus == 0 else {
                continuation.resume(throwing: ShellError(terminationStatus: process.terminationStatus))
                return
            }

            let data = output.fileHandleForReading.readDataToEndOfFile()
            let outputString = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            continuation.resume(returning: outputString)
        }

        do {
            try task.run()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

await main()