import Foundation
import VaporToolbox
import Vapor

let app = boot()

do {
    try app.run().wait()
} catch let error as CommandError {
    let term = Terminal(on: app.eventLoopGroup.next())
    term.error("Error:")
    term.output(error.reason.consoleText())
} catch {
    let term = Terminal(on: app.eventLoopGroup.next())
    term.error("Error:")
    term.output("\(error)".consoleText())
}
