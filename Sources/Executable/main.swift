import Foundation
import VaporToolbox
import ConsoleKit

do {
    try run()
} catch let error as CommandError {
    let term = Terminal()
    term.error("error:")
    term.output(error.reason.consoleText())
} catch {
    let term = Terminal()
    term.error("error:")
    term.output("\(error)".consoleText())
}
