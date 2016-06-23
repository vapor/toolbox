#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import Foundation
import VaporCLI

var iterator = Process.arguments.makeIterator()

// FIXME: Sven: this is actually the path to the binary, not the directory
// not sure why this is called directory, perhaps this used to be run through `dirname`?
guard let directory = iterator.next() else {
    fail("no directory")
}
guard let commandId = iterator.next() else {
    print("Usage: \(directory) [\(VaporCLI.commands.map({ $0.id }).joined(separator: "|"))]")
    fail("no command")
}
guard let command = getCommand(id: commandId, commands: VaporCLI.commands) else {
    fail("command \(commandId) doesn't exist")
}

command.assertDependenciesSatisfied()

let arguments = Array(iterator)
command.execute(with: arguments, in: directory)
exit(0)
