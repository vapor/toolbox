import ConsoleKit
import VaporToolbox

do {
    try run()
} catch {
    let term = Terminal()
    term.output("error: ".consoleText(.error) + "\(error)".consoleText(), newLine: false)
}
