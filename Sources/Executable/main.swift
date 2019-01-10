import Foundation
import VaporToolbox
import Vapor

try ASDF()
throw "done"

do {
    let app = try boot().wait()
    try app.run()
} catch let error as CommandError {
    let term = Terminal()
    term.error("Error:")
    term.output(error.reason.consoleText())
} catch let error as ProcessExecuteError {
    let term = Terminal()
    term.error("Error:")
    term.output(error.stderr.consoleText())
} catch {
    let term = Terminal()
    term.error("Error:")
    term.output("\(error)".consoleText())
}
