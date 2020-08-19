#!/usr/bin/env swift
import Foundation

try print(currentVersion())

func currentVersion() throws -> String {
    do {
        let tag = try shell("git", "describe", "--tags", "--exact-match")
        return tag
    } catch {
        let branch = try shell("git", "symbolic-ref", "-q", "--short", "HEAD")
        let commit = try shell("git", "rev-parse", "--short", "HEAD")
        return "\(branch) (\(commit))"
    }
}

func shell(_ args: String...) throws -> String {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    // grab stdout
    let output = Pipe()
    task.standardOutput = output
    // ignore stderr
    let error = Pipe()
    task.standardError = error
    task.launch()
    task.waitUntilExit()

    guard task.terminationStatus == 0 else {
        throw ShellError(terminationStatus: task.terminationStatus)
    }

    return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

struct ShellError: Error {
    var terminationStatus: Int32
}
