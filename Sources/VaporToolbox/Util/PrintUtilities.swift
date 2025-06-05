import ConsoleKit

/// Styled after PHP's function of the same name.
///
/// How far we've fallen...
func escapeshellarg(_ command: String) -> String {
    #if os(Windows)
    let escaped = command.replacing("\"", with: "^\"")
        .replacing("%", with: "^%")
        .replacing("!", with: "^!")
        .replacing("^", with: "^^")
    return "\"\(escaped)\""
    #else
    "'\(command.replacing("'", with: "'\\''"))'"
    #endif
}

private func printDroplet(on console: some Console) {
    let asciiArt: [String] = [
        "                                ",
        "               **               ",
        "             **~~**             ",
        "           **~~~~~~**           ",
        "         **~~~~~~~~~~**         ",
        "       **~~~~~~~~~~~~~~**       ",
        "     **~~~~~~~~~~~~~~~~~~**     ",
        "   **~~~~~~~~~~~~~~~~~~~~~~**   ",
        "  **~~~~~~~~~~~~~~~~~~~~~~~~**  ",
        " **~~~~~~~~~~~~~~~~~~~~~~~~~~** ",
        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
        "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
        "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
        " **~~~~~~~~~~~~~~~~~~~++++~~~** ",
        "  ***~~~~~~~~~~~~~~~++++~~~***  ",
        "    ****~~~~~~~~~~++++~~****    ",
        "       *****~~~~~~~~~*****      ",
        "          *************         ",
        "                                ",
        " _       __    ___   ___   ___  ",
        #"\ \  /  / /\  | |_) / / \ | |_) "#,
        #" \_\/  /_/--\ |_|   \_\_/ |_| \ "#,
        "  a server framework for Swift  ",
        "                                ",
    ]

    let colors: [Character: ConsoleColor] = [
        "*": .magenta,
        "~": .blue,
        "+": .cyan,
        "_": .magenta,
        "/": .magenta,
        "\\": .magenta,
        "|": .magenta,
        "-": .magenta,
        ")": .magenta,
    ]

    for line in console.center(asciiArt) {
        for character in line {
            console.output(String(character).consoleText(color: colors[character]), newLine: false)
        }
        console.output("", style: .plain, newLine: true)
    }
}

func printNew(project name: String, with cdInstruction: String, on console: some Console, verbose: Bool = false) {
    if verbose { printDroplet(on: console) }

    let projectCreated = "Project \(name.consoleText(.info)) has been created!".consoleText()
    console.output(verbose ? console.center([projectCreated]).first ?? projectCreated : projectCreated)

    if verbose { console.output("") }

    let cdInstruction = "Use " + "cd \(escapeshellarg(cdInstruction))".consoleText(.info) + " to enter the project directory"
    console.output(verbose ? console.center([cdInstruction]).first ?? cdInstruction : cdInstruction)

    let openProject =
        "Then open your project, for example if using Xcode type "
        + "open Package.swift".consoleText(.info)
        + " or "
        + "code .".consoleText(.info)
        + " if using VSCode"
    console.output(verbose ? console.center([openProject]).first ?? openProject : openProject)
}

extension Console {
    /// Outputs to the ``Console`` a combined ``ConsoleText`` from a `key` and `value`.
    ///
    /// ```swift
    /// console.output(key: "name", value: "Vapor")
    /// // name: Vapor
    /// ```
    ///
    /// - Parameters:
    ///   - key: `String` to use as the key, which will precede the `value` an a colon.
    ///   - value: `String` to use as the value.
    ///   - style: ``ConsoleStyle`` to use for printing the `value`.
    public func output(key: String, value: String, style: ConsoleStyle = .info) {
        self.output(key.consoleText() + ": " + value.consoleText(style))
    }
}
