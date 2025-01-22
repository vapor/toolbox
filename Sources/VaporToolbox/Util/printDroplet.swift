func printDroplet() {
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
        // the escaping `\` make these lines look weird, but they're correct
        "\\ \\  /  / /\\  | |_) / / \\ | |_) ",
        " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\ ",
        "   a web framework for Swift    ",
        "                                ",
    ]

    let colors: [Character: ANSIColor] = [
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

    for line in asciiArt {
        for char in line {
            print(char.colored(colors[char]), terminator: "")
        }
        print()
    }
}
