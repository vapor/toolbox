import ConsoleKit
import Foundation

struct Heroku: CommandGroup {
    var commands: [String : AnyCommand] {
        ["init": HerokuInit()]
    }

    var help: String {
        "Commands for working with Heroku"
    }
}
