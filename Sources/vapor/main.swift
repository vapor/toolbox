#!/usr/bin/env swift

#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import Foundation

let version = "0.5.3"

struct VaporCLI {
    // this closure assignment is necessary to be able to exclude Xcode on Linux
    static let commands: [Command.Type] = {
        var c = [Command.Type]()
        c.append(Help)
        c.append(Version)
        c.append(Clean)
        c.append(Build)
        c.append(Run)
        c.append(New)
        c.append(SelfCommands)
        #if os(OSX)
            c.append(Xcode)
        #endif
        c.append(Heroku)
        c.append(Docker)
        return c
    }()
}

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
