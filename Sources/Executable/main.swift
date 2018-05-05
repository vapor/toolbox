import libc
import Console
import Foundation
import VaporToolbox
import Cloud
// The toolbox bootstrap script replaces "master" during installation. Do not modify!
let version = "master"
var arguments = CommandLine.arguments

if arguments.contains("--version") {
    arguments.insert("version", at: 1)
}

let terminal = Terminal(arguments: arguments)

var iterator = arguments.makeIterator()

guard let executable = iterator.next() else {
    throw ConsoleError.noExecutable
}

let cloud = try Cloud.group(terminal)

do {
    try terminal.run(executable: executable, commands: [
        New(console: terminal),
        Build(console: terminal),
        Run(console: terminal),
        Fetch(console: terminal),
        Update(console: terminal),
        Clean(console: terminal),
        Test(console: terminal),
        Xcode(console: terminal),
        Version(console: terminal, version: version),
        cloud,
        Group(id: "heroku", commands: [
            HerokuInit(console: terminal),
            HerokuPush(console: terminal),
        ], help: [
            "Commands to help deploy to Heroku."
        ]),
        Group(id: "provider", commands: [
            ProviderAdd(console: terminal)
        ], help: [
            "Commands to help manage providers."
        ]),
    ], arguments: Array(iterator), help: [
        "Join our Discord if you have questions, need help,",
        "or want to contribute: http://discord.gg/BnXmVGA"
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
} catch let error as AbortError {
    terminal.error("API Error (\(error.status)): ", newLine: false)
    terminal.print(error.reason)
} catch {
    terminal.error("Error: ", newLine: false)
    terminal.print("\(error)")
    exit(1)
}
