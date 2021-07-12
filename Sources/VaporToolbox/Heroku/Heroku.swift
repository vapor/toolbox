import ConsoleKit
import Foundation

struct Heroku: CommandGroup {
    var commands: [String : AnyCommand] {
        [
            "init": HerokuInit(),
            "push": HerokuPush(),
        ]
    }

    var help: String {
        "Commands for working with Heroku."
    }
}
