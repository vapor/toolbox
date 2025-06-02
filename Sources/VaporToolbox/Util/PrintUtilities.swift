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
            console.output(character.consoleText(color: colors[character]), newLine: false)
        }
        console.output("", style: .plain, newLine: true)
    }
}

func printNew(project name: String, with cdInstruction: String, on console: some Console, verbose: Bool = false) {
    if verbose { printDroplet(on: console) }

    let projectCreated = "Project \(name.consoleText(.info)) has been created!".consoleText()
    console.output(verbose ? console.center(projectCreated) : projectCreated)

    if verbose { console.output("") }

    let cdInstruction = "Use " + "cd \(escapeshellarg(cdInstruction))".consoleText(.info) + " to enter the project directory"
    console.output(verbose ? console.center(cdInstruction) : cdInstruction)

    let openProject = "Then open your project, for example if using Xcode type "
        + "open Package.swift".consoleText(.info)
        + " or "
        + "code .".consoleText(.info)
        + " if using VSCode"
    console.output(verbose ? console.center(openProject) : openProject, newLine: false)
    console.output("", newLine: true)
}
