import XCTest
import Console
import libc
@testable import VaporToolbox

final class TestConsole: ConsoleProtocol {
    var inputBuffer: [String]
    var outputBuffer: [String]
    var executeBuffer: [String]
    var backgroundExecuteOutputBuffer: [String: String]
    var newLine: Bool

    init() {
        inputBuffer = []
        outputBuffer = []
        executeBuffer = []
        backgroundExecuteOutputBuffer = [:]

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

    func execute(program: String, arguments: [String], input: Int32?, output: Int32?, error: Int32?) throws {
        exec(program)
    }

    func backgroundExecute(program: String, arguments: [String]) throws -> String {
        exec(program)
        return backgroundExecuteOutputBuffer[program] ?? ""
    }

    private func exec(_ command: String) {
        executeBuffer.append(command)
    }
}
