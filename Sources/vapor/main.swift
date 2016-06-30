#!/usr/bin/env swift

import Foundation
import VaporCLI


enum ReturnCodes: Int32 {
    case ok = 0
    case cancelled
    case failed
    case unexpected
}


var args = Process.arguments.makeIterator()

guard let binary = args.next() else {
    // this cannot really happen as argv[0] is the command itself
    print("no binary")
    exit(ReturnCodes.unexpected.rawValue)
}
guard let commandId = args.next() else {
    print("Usage: \(binary) [\(VaporCLI.commands.map({ $0.id }).joined(separator: "|"))]")
    print("Please specify a command")
    exit(ReturnCodes.failed.rawValue)
}
guard let command = getCommand(id: commandId, commands: VaporCLI.commands) else {
    print("command \(commandId) doesn't exist, run '\(binary) help' for help")
    exit(ReturnCodes.failed.rawValue)
}


do {
    try command.assertDependenciesSatisfied()
    try command.execute(with: Array(args))
    exit(ReturnCodes.ok.rawValue)
} catch Error.cancelled(let msg) {
    print()
    print("Error: \(msg)")
    exit(ReturnCodes.cancelled.rawValue)
} catch Error.failed(let msg) {
    print()
    print("Error: \(msg)")
    print("Note: Make sure you are using Swift 3.0 Snapshot 06-06")
    exit(ReturnCodes.failed.rawValue)
} catch {
    print("unexpected error")
    exit(ReturnCodes.unexpected.rawValue)
}
