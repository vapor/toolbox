import libc
import Console
import Foundation
import VaporToolbox

// The toolbox bootstrap script replaces "master" during installation. Do not modify!
let version = "master"
let arguments = CommandLine.arguments
let terminal = Terminal(arguments: arguments)

var iterator = arguments.makeIterator()

guard let executable = iterator.next() else {
    throw ConsoleError.noExecutable
}

do {
    try terminal.run(executable: executable, commands: [
        New(console: terminal),
        Build(console: terminal),
        Update(console: terminal),
        Run(console: terminal),
        Fetch(console: terminal),
        Clean(console: terminal),
        Test(console: terminal),
        Xcode(console: terminal),
        Version(console: terminal, version: version),
        Group(id: "self", commands: [
            SelfInstall(console: terminal, executable: executable, version: version),
            SelfUpdate(console: terminal, executable: executable),

        ], help: [
            "Commands that affect the toolbox itself."
        ]),
        Group(id: "heroku", commands: [
            HerokuInit(console: terminal),
            HerokuPush(console: terminal),
        ], help: [
            "Commands to help deploy to Heroku."
        ]),
    ], arguments: Array(iterator), help: [
        "Join our Slack if you have questions, need help,",
        "or want to contribute: http://vapor.team"
    ])
} catch ToolboxError.general(let message) {
    terminal.error("Error: ", newLine: false)
    terminal.print(message)
    exit(1)
} catch ConsoleError.insufficientArguments {
    terminal.error("Error: ", newLine: false)
    terminal.print("Insufficient arguments.")
} catch ConsoleError.help {
    exit(0)
} catch ConsoleError.cancelled {
    print("Cancelled")
    exit(2)
} catch ConsoleError.noCommand {
    terminal.error("Error: ", newLine: false)
    terminal.print("No command supplied.")
} catch ConsoleError.commandNotFound(let id) {
    terminal.error("Error: ", newLine: false)
    terminal.print("Command \"\(id)\" not found.")
} catch {
    terminal.error("Error: ", newLine: false)
    terminal.print("\(error)")
    exit(1)
}
