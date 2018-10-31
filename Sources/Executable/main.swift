import Foundation
import VaporToolbox
import Vapor

do {
    let app = try boot().wait()
    try app.run()
} catch {
    let term = Terminal()
    term.error("Error:")
    term.output("\(error)".consoleText())
}
