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
            ("test_help", test_help),
        ]
    }


    override func setUp() {
        // reset test shell
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


    func test_help() {
        XCTAssert(Build.help.count > 0)
    }

}
