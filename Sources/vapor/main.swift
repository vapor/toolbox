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

let arguments = Array(iterator)
command.execute(with: arguments)
exit(0)
