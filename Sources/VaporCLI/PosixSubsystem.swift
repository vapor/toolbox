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
public struct Shell {
    // wrappers for a few low level C calls, based on
    // https://github.com/apple/swift-package-manager/blob/master/Sources/POSIX/system.swift

    private func _WSTATUS(_ status: CInt) -> CInt {
        return status & 0x7f
    }

    private func WIFEXITED(_ status: CInt) -> Bool {
        return _WSTATUS(status) == 0
    }

    private func WEXITSTATUS(_ status: CInt) -> CInt {
        return (status >> 8) & 0xff
    }

    func waitpid(_ pid: pid_t) throws -> Int32 {
        while true {
            var exitStatus: Int32 = 0
            let rv = libc.waitpid(pid, &exitStatus, 0)

            if rv != -1 {
                if WIFEXITED(exitStatus) {
                    return WEXITSTATUS(exitStatus)
                } else {
                    throw Error.system(exitStatus)
                }
            } else if errno == EINTR {
                continue  // see: man waitpid
            } else {
                throw Error.system(errno)
            }
        }
    }

    func posix_spawnp(args: [String]) throws -> pid_t {
        var environment = [String: String]()
        for key in ["PATH", "HOME"] {
            if let e = getenv(key) {
                environment[key] = String(validatingUTF8: e)
            }
        }

        let env: [UnsafeMutablePointer<CChar>?] = environment.map{ "\($0.0)=\($0.1)".withCString(strdup) }
        defer { for case let arg? in env { free(arg) } }

        var pid: pid_t = 0
        let argv = args.map{ $0.withCString(strdup) } + [nil]
        defer { for case let arg? in argv { free(arg) } }

        let res = libc.posix_spawnp(&pid, argv[0], nil, nil, argv, env + [nil])

        if res == 0 {
            return pid
        } else {
            throw Error.system(res)
        }
    }
    
}


extension Shell: PosixSubsystem {

    public func system(_ command: String) -> Int32 {
        let parts: [String]
        if !command.hasPrefix("/") {
            parts = ["/bin/sh", "-c", command]
        } else {
            // FIXME: remove after Grand Renaming lands on Linux
            #if os(OSX)
                parts = command.components(separatedBy: CharacterSet.whitespaces)
            #else
                parts = command.components(separatedBy: NSCharacterSet.whitespaces())
            #endif
        }
        do {
            let pid = try posix_spawnp(args: parts)
            return try waitpid(pid)
        } catch {
            // FIXME: mark method 'throws' and throw
            //            throw Error.failed("Failed to spawn subprocess '\(command)'")
            return -1
        }
    }

    public func fileExists(_ path: String) -> Bool {
        return system("ls \(path) > /dev/null 2>&1") == 0
    }

    public func commandExists(_ command: String) -> Bool {
        return system("hash \(command) 2>/dev/null") == 0
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

        // FIXME: remove after Grand Renaming lands on Linux
        #if os(OSX)
            let task = Task()
            let pipe = Pipe()
        #else
            let task = NSTask()
            let pipe = NSPipe()
        #endif
        task.launchPath = command
        task.arguments = arguments
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        // FIXME: remove after Grand Renaming lands on Linux
        #if os(OSX)
            let stdout = String(data: data, encoding: String.Encoding.utf8)
        #else
            let stdout = String(data: data, encoding: NSUTF8StringEncoding)
        #endif
        return (status, stdout, nil)
    }

}


