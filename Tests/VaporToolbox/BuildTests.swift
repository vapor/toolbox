//
//  BuildTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class BuildTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (BuildTests) -> () throws -> Void)] {
        return [
            ("test_execute", test_execute),
            ("test_execute_args", test_execute_args),
            ("test_execute_release", test_execute_release),
            ("test_execute_fetch_cancelled", test_execute_fetch_cancelled),
            ("test_execute_fetch_failed", test_execute_fetch_failed),
            ("test_execute_build_cancelled", test_execute_build_cancelled),
            ("test_execute_build_failed", test_execute_build_failed),
            ("test_help", test_help),
        ]
    }


    override func setUp() {
        TestSystem.reset()
    }


    // MARK: Tests


    func test_execute() {
        do {
            try Build.execute(with: [], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .ok("swift build ")])
        } catch {
            XCTFail("unexpected error")
        }
    }

    
    func test_execute_args() {
        do {
            try Build.execute(with: ["foo", "-bar"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .ok("swift build foo -bar")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_release() {
        do {
            try Build.execute(with: ["--release"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .ok("swift build -c release")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_fetch_cancelled() {
        TestSystem.shell.commandResults = { cmd in
            if cmd == "swift package fetch" {
                return .error(2)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Build.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.cancelled(let msg) {
            XCTAssertEqual(msg, "Fetch cancelled")
            XCTAssertEqual(TestSystem.log, [.error(2)])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_fetch_failed() {
        TestSystem.shell.commandResults = { cmd in
            if cmd == "swift package fetch" {
                // return some error code other than 2 (cancelled)
                return .error(3)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Build.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "Could not fetch dependencies.")
            XCTAssertEqual(TestSystem.log, [.error(3)])
        } catch {
            XCTFail("unexpected error")
        }
    }

    
    func test_execute_build_cancelled() {
        TestSystem.shell.commandResults = { cmd in
            if cmd.hasPrefix("swift build") {
                return .error(2)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Build.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.cancelled(let msg) {
            XCTAssertEqual(msg, "Build cancelled")
            XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .error(2)])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_build_failed() {
        TestSystem.shell.commandResults = { cmd in
            if cmd.hasPrefix("swift build") {
                // return some error code other than 2 (cancelled)
                return .error(3)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Build.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "Could not build project.")
            XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .error(3)])
        } catch {
            XCTFail("unexpected error")
        }
    }

    
    func test_help() {
        XCTAssert(Build.help.count > 0)
    }

}
