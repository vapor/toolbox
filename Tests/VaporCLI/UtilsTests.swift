//
//  UtilsTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI


class UtilsTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (UtilsTests) -> () throws -> Void)] {
        return [
            ("test_ShellCommand_run", test_ShellCommand_run),
            ("test_ShellCommand_run_cancelled", test_ShellCommand_run_cancelled),
            ("test_ShellCommand_run_error", test_ShellCommand_run_error),
        ]
    }

    func test_ShellCommand_run() {
        var executed = [LogEntry]()
        let shell = TestSystem(logEvent: { executed.append($0) })
        do {
            try shell.run("ls -l")
            // don't even need to wrap the String as it's typealised to ShellCommand:
            try shell.run("ls -la")
            XCTAssertEqual(executed, [.ok("ls -l"), .ok("ls -la")])
        } catch {
            XCTFail()
        }
    }

    func test_ShellCommand_run_cancelled() {
        var shell = TestSystem()
        shell.commandResults = { _ in .error(2) }
        do {
            try shell.run("foo")
            XCTFail()
        } catch Error.cancelled {
            // ok
        } catch {
            XCTFail()
        }
    }

    func test_ShellCommand_run_error() {
        var shell = TestSystem()
        shell.commandResults = { _ in .error(1) }
        do {
            try shell.run("foo")
            XCTFail()
        } catch Error.system(let res) {
            XCTAssertEqual(res, 1)
        } catch {
            XCTFail()
        }
    }

}
