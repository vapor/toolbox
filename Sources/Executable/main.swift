import ConsoleKit
import VaporToolbox

do {
    try run()
} catch {
    let term = Terminal()
    term.list(.error, key: "Error", value: "\(error)")
}
