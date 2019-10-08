import ConsoleKit
import VaporToolbox

do {
    try run()
} catch let error as CommandError {
    let term = Terminal()
    term.error("error:")
    term.output("reason: " + error.reason.consoleText())
    term.output("identifier: " + error.identifier.consoleText())
} catch {
    let term = Terminal()
    term.error("error:")
    term.output("\(error)".consoleText())
}
