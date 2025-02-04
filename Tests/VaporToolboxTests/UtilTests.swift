import Foundation
import Testing

@testable import VaporToolbox

@Suite("Util Tests")
struct UtilTests {
    @Test("Process.runUntilExit")
    func runUntilExit() throws {
        let process = try Process.runUntilExit(URL(filePath: "/bin/sh"), arguments: ["-c", "echo 'Hello, World!'"])
        #expect(process.outputString == "Hello, World!")

        #expect {
            try Process.runUntilExit(URL(filePath: "/bin/sh"), arguments: ["-c", "exit 1"])
        } throws: { error in
            guard let error = error as? ProcessError else { return false }
            return error.description == ""
        }
    }

    @Test("which")
    func which() throws {
        print(try Process.shell.which("ls").path())
        #expect(try Process.shell.which("ls").path() == "/bin/ls")
        #expect(try Process.shell.which("cat").path() == "/bin/cat")  // Issue #403
    }

    @Test("escapeshellarg")
    func escapeshellarg() {
        var string: String
        var escapedString: String { Process.shell.escapeshellarg(string) }

        string = "Hello, World!"
        #expect(escapedString == "'Hello, World!'")

        string = "Hello, 'World'!"
        #expect(escapedString == "'Hello, '\\''World'\\''!'")
    }

    @Test("ANSI Color")
    func ansiColor() {
        let color = ANSIColor.black
        #expect(color.rawValue == "\u{001B}[30m")

        let string = "Hello, World!"
        let coloredString = string.colored(color)
        #expect(coloredString == "\u{001B}[30mHello, World!\u{001B}[0m")

        let substring = "Hello, World!".prefix(5)
        let coloredSubstring = substring.colored(color)
        #expect(coloredSubstring == "\u{001B}[30mHello\u{001B}[0m")

        let character: Character = "H"
        let coloredCharacter = character.colored(color)
        #expect(coloredCharacter == "\u{001B}[30mH\u{001B}[0m")

        let noColor: ANSIColor? = nil
        let noColoredCharacter = character.colored(noColor)
        #expect(noColoredCharacter == "H")
    }

    @Test("printDroplet()")
    func droplet() async throws {
        printDroplet()
    }
}
