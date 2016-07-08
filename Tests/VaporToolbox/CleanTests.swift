//
//  CleanTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class CleanTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (CleanTests) -> () throws -> Void)] {
        return [
            ("test_execute", test_execute),
            ("test_execute_args", test_execute_args),
        ]
    }


    override func setUp() {
        TestSystem.reset()
    }


    // MARK: Tests


    func test_execute() {
        do {
            try Clean.execute(with: [], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("rm -rf Packages .build")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_args() {
        do {
            try Clean.execute(with: ["foo", "-bar"], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "clean does not take any additional parameters")
            XCTAssertEqual(TestSystem.log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }

}
