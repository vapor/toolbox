import ConsoleKit

struct Supervisor: CommandGroup {
    var commands: [String : AnyCommand] {
        [
            "init": SupervisorInit(),
            "update": SupervisorUpdate(),
            "restart": SupervisorRestart(),
        ]
    }

    var help: String {
        "Commands for working with supervisord."
    }
}
