import ConsoleKit

struct SupervisorCommand: CommandGroup {
    var commands: [String : AnyCommand] {
        [
            "init": SupervisorInit(),
            "update": SupervisorUpdate(),
        ]
    }

    var help: String {
        "Commands for working with Supervisord"
    }
}
