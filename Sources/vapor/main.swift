#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import Foundation
import VaporCLI

var iterator = Process.arguments.makeIterator()

guard let binary = iterator.next() else {
    fail("no binary")
}
guard let commandId = iterator.next() else {
    print("Usage: \(binary) [\(VaporCLI.commands.map({ $0.id }).joined(separator: "|"))]")
    fail("no command")
}
guard let command = getCommand(id: commandId, commands: VaporCLI.commands) else {
    fail("command \(commandId) doesn't exist")
}

command.assertDependenciesSatisfied()

do {
    let arguments = Array(iterator)
    try command.execute(with: arguments)
    exit(0)
} catch Error.cancelled(let msg) {
    print()
    print("Error: \(msg)")
    exit(1)
} catch Error.failed(let msg) {
    print()
    print("Error: \(msg)")
    print("Note: Make sure you are using Swift 3.0 Snapshot 06-06")
    exit(2)
} catch {
    print("unexpected error")
    exit(3)
}
