#!/usr/bin/env swift
import Foundation

try build()

func build() throws {
    try withVersion(in: "Sources/VaporToolbox/Version.swift", as: currentVersion()) {
        try foregroundShell(
            "swift", "build",
            "--disable-sandbox",
            "--configuration", "release",
            "-Xswiftc", "-cross-module-optimization"
        )
    }
}

func withVersion(in file: String, as version: String, _ closure: () throws -> ()) throws {
    let fileURL = URL(fileURLWithPath: file)
    let originalFileContents = try String(contentsOf: fileURL, encoding: .utf8)
    // set version
    try originalFileContents
        .replacingOccurrences(of: "nil", with: "\"\(version)\"")
        .write(to: fileURL, atomically: true, encoding: .utf8)
    defer {
        // undo set version
        try! originalFileContents
            .write(to: fileURL, atomically: true, encoding: .utf8)
    }
    // run closure
    try closure()
}

func currentVersion() throws -> String {
    do {
        let tag = try backgroundShell("git", "describe", "--tags", "--exact-match")
        return tag
    } catch {
        let branch = try backgroundShell("git", "symbolic-ref", "-q", "--short", "HEAD")
        let commit = try backgroundShell("git", "rev-parse", "--short", "HEAD")
        return "\(branch) (\(commit))"
    }
}

func foregroundShell(_ args: String...) throws {
    print("$", args.joined(separator: " "))
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = args
    try task.run()
    task.waitUntilExit()

    guard task.terminationStatus == 0 else {
        throw ShellError(terminationStatus: task.terminationStatus)
    }
}

@discardableResult
func backgroundShell(_ args: String...) throws -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = args
    // grab stdout
    let output = Pipe()
    task.standardOutput = output
    // ignore stderr
    let error = Pipe()
    task.standardError = error
    try task.run()
    task.waitUntilExit()

    guard task.terminationStatus == 0 else {
        throw ShellError(terminationStatus: task.terminationStatus)
    }

    return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

struct ShellError: Swift.Error {
    var terminationStatus: Int32
}
