//
//  TestSystem.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 27/06/2016.
//
//

import Foundation
@testable import VaporCLI


// MARK: LogEntry

enum LogEntry: Equatable {
    case ok(String)
    case error(Int32)
    case failed(String)

    var ok: String? {
        switch self {
        case .ok(let value):
            return value
        default:
            return nil
        }
    }
}


func ==(lhs: LogEntry, rhs: LogEntry) -> Bool {
    switch (lhs, rhs) {
    case let (.ok(left), .ok(right)):
        return left == right
    case let (.error(left), .error(right)):
        return left == right
    case let (.failed(left), .failed(right)):
        return left == right
    default:
        return false
    }
}


// MARK: TestSystem


struct TestSystem {
    let logEvent: (LogEntry) -> ()
    var commandResults: ((ShellCommand) -> LogEntry)?
    var fileExists = false
    var commandExists = true

    init(logEvent: (LogEntry) -> () = {_ in }) {
        self.logEvent = logEvent
    }
}


extension TestSystem: PosixSubsystem {

    static var log = [LogEntry]()
    static var shell = TestSystem(logEvent: { log.append($0) })
    
    static func reset() {
        log.removeAll()
        shell = TestSystem(logEvent: { log.append($0) })
    }

    func system(_ command: String) -> Int32 {
        let log = self.commandResults?(command) ?? .ok(command)
        self.logEvent(log)
        switch log {
        case .ok:
            return 0
        case .error(let code):
            return code
        case .failed:
            return 127
        }
    }

    func fileExists(_ path: String) -> Bool {
        return fileExists
    }

    func commandExists(_ command: String) -> Bool {
        return commandExists
    }

    func fail(_ message: String, cancelled: Bool) {
        self.logEvent(.failed(message))
    }
    
}

