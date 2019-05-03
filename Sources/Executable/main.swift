import Foundation
import VaporToolbox
import ConsoleKit

//try testExample()
//let app = boot()

do {
    try _boot()
//    try app.run()
//    try app.run().wait()
} catch let error as CommandError {
    let term = Terminal()
    term.error("Error:")
    term.output(error.reason.consoleText())
} catch {
    let term = Terminal()
    term.error("Error:")
    term.output("\(error)".consoleText())
}
