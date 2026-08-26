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
    let dropletArt: [String] = [
        "                                                                                                    ",
        "                                                 ==                                                 ",
        "                                               ======                                               ",
        "                                              ========                                              ",
        "                                             ==========                                             ",
        "                                           ==============                                           ",
        "                                          ================                                          ",
        "                                           ==============                                           ",
        "                                                                                                    ",
        "                                      ++++                ++++                                      ",
        "                                     ++++++++++++++++++++++++++                                     ",
        "                                    ++++++++++++++++++++++++++++                                    ",
        "                                   ++++++++++++++++++++++++++++++                                   ",
        "                                  ++++++++++++++++++++++++++++++++                                  ",
        "                                  ++++++++++++++++++++++++++++++++                                  ",
        "                               *    ++++++++++++++++++++++++++++    *                               ",
        "                              ***       ++++++++++++++++++++       ***                              ",
        "                             ******                              ******                             ",
        "                            ************                    ************                            ",
        "                           **********************************************                           ",
        "                           **********************************************                           ",
        "                           **********************************************                           ",
        "                            ********************************************                            ",
        "                        #     ****************************************     #                        ",
        "                       ####       ********************************       ####                       ",
        "                       ######           ********************           ######                       ",
        "                      ###########                                  ###########                      ",
        "                      ####################                ####################                      ",
        "                      ########################################################                      ",
        "                      ########################################################                      ",
        "                       ######################################################                       ",
        "                         ##################################################                         ",
        "                            ############################################                            ",
        "                       ++        ##################################        ++                       ",
        "                        +++++               ############               +++++                        ",
        "                         ++++++++++                              ++++++++++                         ",
        "                          ++++++++++++++++++++++++++++++++++++++++++++++++                          ",
        "                           ++++++++++++++++++++++++++++++++++++++++++++++                           ",
        "                            ++++++++++++++++++++++++++++++++++++++++++++                            ",
        "                              ++++++++++++++++++++++++++++++++++++++++                              ",
        "                                ++++++++++++++++++++++++++++++++++++                                ",
        "                                  ++++++++++++++++++++++++++++++++                                  ",
        "                                     ++++++++++++++++++++++++++                                     ",
        "                                         ++++++++++++++++++                                         ",
        "                                                                                                    ",
    ]

    let textArt: [String] = [
        " _       __    ___   ___   ___  ",
        #"\ \  /  / /\  | |_) / / \ | |_) "#,
        #" \_\/  /_/--\ |_|   \_\_/ |_| \ "#,
        "  a server framework for Swift  ",
        "                                ",
    ]

    let textColors: [Character: ConsoleColor] = [
        "_": .magenta,
        "/": .magenta,
        "\\": .magenta,
        "|": .magenta,
        "-": .magenta,
        ")": .magenta,
    ]

    // `+` appears in both the upper ring (lines 9–16) and the lower ring (lines 33–43).
    // Pick a threshold between those ranges so each ring gets its own color.
    let lowerRingStart = 25
    func dropletColor(for character: Character, lineIndex: Int) -> ConsoleColor? {
        switch character {
        case "=": .custom(r: 63, g: 184, b: 248)
        case "+": lineIndex < lowerRingStart
            ? .custom(r: 74, g: 125, b: 232)
            : .custom(r: 217, g: 79, b: 227)
        case "*": .custom(r: 91, g: 90, b: 200)
        case "#": .custom(r: 154, g: 85, b: 232)
        default: nil
        }
    }

    for (lineIndex, line) in console.center(dropletArt).enumerated() {
        for character in line {
            console.output(
                String(character).consoleText(color: dropletColor(for: character, lineIndex: lineIndex)),
                newLine: false
            )
        }
        console.output("", style: .plain, newLine: true)
    }

    for line in console.center(textArt) {
        for character in line {
            console.output(String(character).consoleText(color: textColors[character]), newLine: false)
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
        "Then to open your project with Xcode type: "
        + "open Package.swift".consoleText(.info)
        + " or to open with Visual Studio Code type: "
        + "code .".consoleText(.info)
    console.output(verbose ? console.center([openProject]).first ?? openProject : openProject)
}

extension Console {
    /// Outputs to the ``Console`` a combined `ConsoleText` from a `key` and `value`.
    ///
    /// ```swift
    /// console.output(key: "name", value: "Vapor")
    /// // name: Vapor
    /// ```
    ///
    /// - Parameters:
    ///   - key: `String` to use as the key, which will precede the `value` an a colon.
    ///   - value: `String` to use as the value.
    ///   - style: `ConsoleStyle` to use for printing the `value`.
    func output(key: String, value: String, style: ConsoleStyle = .info) {
        self.output(key.consoleText() + ": " + value.consoleText(style))
    }
}
