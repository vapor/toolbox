//
//  VaporCLITests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 30/06/2016.
//
//

import XCTest
@testable import VaporCLI


class VaporCLITests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (VaporCLITests) -> () throws -> Void)] {
        return [
            ("test_commands", test_commands),
            ("test_usage", test_usage),
            ("test_execute", test_execute),
            ("test_execute_missing_command", test_execute_missing_command),
            ("test_execute_no_args", test_execute_no_args),
            ("test_execute_invalid_command", test_execute_invalid_command),
        ]
    }


    override func setUp() {
        TestSystem.reset()
    }


    // MARK: Tests


    func test_commands() {
        #if os(OSX)
            XCTAssertEqual(VaporCLI.subCommands.count, 10)
        #else
            XCTAssertEqual(VaporCLI.subCommands.count, 9)
        #endif
    }


    func test_usage() {
        XCTAssert(VaporCLI.usage.hasPrefix("Usage: vapor"), "wrong prefix, actual: \(VaporCLI.usage)")
    }


    func test_execute() {
        // test one command to make sure the wiring is ok
        // the actual commands are tested in detail in their own tests
        do {
            try VaporCLI.execute(with: ["vapor", "clean"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("rm -rf Packages .build")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_missing_command() {
        do {
            try VaporCLI.execute(with: ["vapor"], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(
                msg,
                ["Please specify a command", VaporCLI.usage].joined(separator: "\n")
            )
            XCTAssertEqual(TestSystem.log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_no_args() {
        do {
            try VaporCLI.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(
                msg,
                ["Please specify a command", VaporCLI.usage].joined(separator: "\n")
            )
            XCTAssertEqual(TestSystem.log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_invalid_command() {
        do {
            try VaporCLI.execute(with: ["vapor", "foo"], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssert(msg.hasPrefix("Unknown vapor subcommand 'foo'"), "wrong prefix, actual: \(msg)")
            XCTAssertEqual(TestSystem.log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }

}
