//
//  PosixSubsystem.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 30/06/2016.
//
//

import Foundation
import libc


public typealias CommandResult = (status: Int32, stdout: String?, stderr: String?)


// MARK:- PosixSubsystem


public protocol PosixSubsystem {
    func system(_ command: String) -> Int32
    func fileExists(_ path: String) -> Bool
    func commandExists(_ command: String) -> Bool
    func getInput() -> String?
    func terminalSize() -> (width: Int, height: Int)?
    func printFancy(_ string: String)
    func runWithOutput(_ command: String) throws -> CommandResult
}


extension PosixSubsystem {
    func passes(_ command: String) -> Bool {
        return self.system(command) == 0
    }
}


extension PosixSubsystem {
    func run(_ command: String) throws {
        // FIXME: replace with `runWithOutput(command).status`
        let result = self.system(command)

        if result == 2 {
            throw Error.cancelled(command)
        } else if result != 0 {
            throw Error.system(result)
        }
    }
}


extension PosixSubsystem {
    func printFancy(_ strings: [String]) {
        printFancy(strings.joined(separator: "\n"))
    }
}


// MARK:- Error


public enum Error: ErrorProtocol {
    case system(Int32)
    case failed(String) // user facing error, thrown by execute
    case cancelled(String)
}


// MARK:- Shell


// FIXME: add tests
public struct Shell: PosixSubsystem {

    public func system(_ command: String) -> Int32 {
        return libc.system(command)
    }

    public func fileExists(_ path: String) -> Bool {
        return libc.system("ls \(path) > /dev/null 2>&1") == 0
    }

    public func commandExists(_ command: String) -> Bool {
        return libc.system("hash \(command) 2>/dev/null") == 0
    }

    public func getInput() -> String? {
        return readLine(strippingNewline: true)
    }

    public func terminalSize() -> (width: Int, height: Int)? {
        // Get the columns and lines from tput
        let tput = "/usr/bin/tput"
        if let
            str_cols = (try? runWithOutput(tput + " cols"))?.stdout?.trim(),
            str_lines = (try? runWithOutput(tput + " lines"))?.stdout?.trim(),
            cols = Int(str_cols),
            lines = Int(str_lines) {
            return (cols, lines)
        } else {
            return nil
        }
    }

    public func printFancy(_ string: String) {
        let centered: String
        if let size = terminalSize() {
            centered = string.centerTextBlock(width: size.width)
        } else {
            centered = string
        }

        let fancy = centered.colored(with: [
            "*": .magenta,
            "~": .blue,
            "+": .cyan, // Droplet
            "_": .magenta,
            "/": .magenta,
            "\\": .magenta,
            "|": .magenta,
            "-": .magenta,
            ")": .magenta // Title
            ])
        
        print(fancy)
    }

    public func runWithOutput(_ command: String) throws -> CommandResult {
        let parts = command.components(separatedBy: NSCharacterSet.whitespaces())
        guard parts.count > 0 else {
            throw Error.failed("Invalid command")
        }

        let command = parts[0]
        let arguments = Array(parts.dropFirst())

        let task = NSTask()
        task.launchPath = command
        task.arguments = arguments
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: data, encoding: NSUTF8StringEncoding)
        return (status, stdout, nil)
    }

}


