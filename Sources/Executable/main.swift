import Foundation
import VaporToolbox
import Vapor

//try testCloud()

do {
    let app = try boot().wait()
    try app.run()
} catch {
    let term = Terminal()
    term.output("Error:", style: .error)
    term.output("\(error)".consoleText())
}
