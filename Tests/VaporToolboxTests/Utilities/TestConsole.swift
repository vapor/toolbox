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

    // MARK: Protocol conformance
    var confirmOverride: Bool?
    var size: (width: Int, height: Int)

    init() {
        inputBuffer = []
        outputBuffer = []
        executeBuffer = []
        backgroundExecuteOutputBuffer = [:]

        confirmOverride = true
        size = (0, 0)
        newLine = false
    }


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

    func secureInput() -> String {
        return input()
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
        exec(program, args: arguments)
    }

    func backgroundExecute(program: String, arguments: [String]) throws -> String {
        exec(program, args: arguments)
        let command = program + " " + arguments.joined(separator: " ")
        guard let val = backgroundExecuteOutputBuffer[command] else {
            throw ToolboxError.general("No command set for '\(command)'")
        }
        return val
    }

    private func exec(_ command: String, args: [String]) {
        executeBuffer.append(command + (!args.isEmpty ? " " + args.joined(separator: " ") : ""))
    }

    /// Upon a console instance being killed for example w/ ctrl+c
    /// a console should forward the message to kill listeners
    func registerKillListener(_ listener: @escaping (Int32) -> Void) {
    }
}
