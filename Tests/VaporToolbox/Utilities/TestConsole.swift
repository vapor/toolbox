import XCTest
import Console
import libc
@testable import VaporToolbox

final class TestConsole: Console {
    var inputBuffer: [String]
    var outputBuffer: [String]
    var executeBuffer: [String]
    var subExecuteOutputBuffer: [String: String]
    var newLine: Bool

    init() {
        inputBuffer = []
        outputBuffer = []
        executeBuffer = []
        subExecuteOutputBuffer = [:]

        confirmOverride = nil
        size = (0, 0)
        newLine = false
    }

    // MARK: Protocol conformance 

    var confirmOverride: Bool?
    var size: (width: Int, height: Int)

    func output(_ string: String, style: ConsoleStyle, newLine: Bool) {
        if self.newLine {
            self.newLine = false
            outputBuffer.append("")
        }

        let last = outputBuffer.last ?? ""
        outputBuffer = Array(outputBuffer.dropLast())
        outputBuffer.append(last + string)

        self.newLine = newLine
    }


    func input() -> String {
        let input = inputBuffer.joined(separator: "\n")
        inputBuffer = []
        return input
    }

    func clear(_ clear: ConsoleClear) {
        switch clear {
        case .line:
            outputBuffer = Array(outputBuffer.dropLast())
        case .screen:
            outputBuffer = []
        }
    }

    func execute(_ command: String) throws {
        exec(command)
    }

    func subexecute(_ command: String, input: String) throws -> String {
        exec(command)
        return subExecuteOutputBuffer[command] ?? ""
    }

    private func exec(_ command: String) {
        executeBuffer.append(command)
    }
}
