import Foundation

#if canImport(Android)
import Android
#endif

#if os(Windows)
import WinSDK
#endif

extension String {
    fileprivate var centered: String {
        // Split the string into lines
        var lines = self.split(separator: "\n").map(String.init)

        guard !lines.isEmpty else {
            return ""
        }

        // Remove ANSI color codes to get the true length of the string
        let uncoloredLines = lines.map { $0.removingANSIColors }

        var longestLine = 0
        for line in uncoloredLines {
            longestLine = max(longestLine, line.count)
        }

        // Calculate the padding and make sure it's greater than or equal to 0
        let padding = max(0, (terminalSize.width - longestLine) / 2)

        // Apply the padding to each line
        for i in lines.indices {
            lines[i].insert(contentsOf: String(repeating: " ", count: padding), at: lines[i].startIndex)
        }

        return lines.joined(separator: "\n")
    }

    var removingANSIColors: String {
        var result = ""
        var isEscaped = false
        for char in self {
            if isEscaped {
                if char == "m" {
                    isEscaped = false
                }
            } else if char == "\u{1B}" {
                isEscaped = true
            } else {
                result.append(char)
            }
        }
        return result
    }
}

private var terminalSize: (width: Int, height: Int) {
    #if os(Windows)
    var csbi = CONSOLE_SCREEN_BUFFER_INFO()
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)
    return (Int(csbi.dwSize.X), Int(csbi.dwSize.Y))
    #else
    var w = winsize()
    _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
    return (Int(w.ws_col), Int(w.ws_row))
    #endif
}

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

private func printDroplet() {
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
        let centeredLine = line.centered
        for char in centeredLine {
            print(char.colored(colors[char]), terminator: "")
        }
        print()
    }
}

func printNew(project name: String, with path: String, verbose: Bool = false) {
    if verbose { printDroplet() }

    let projectCreated = "Project \(name.colored(.cyan)) has been created!"
    print(verbose ? projectCreated.centered : projectCreated)

    if verbose { print() }

    let cdInstruction = "Use " + "cd \(escapeshellarg(path))".colored(.cyan) + " to enter the project directory"
    print(verbose ? cdInstruction.centered : cdInstruction)

    let openProject =
        "Then open your project, for example if using Xcode type "
        + "open Package.swift".colored(.cyan)
        + " or "
        + "code .".colored(.cyan)
        + " if using VSCode"
    print(verbose ? openProject.centered : openProject)
}
