//
//  RunTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class RunTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (RunTests) -> () throws -> Void)] {
        return [
            ("test_execute", test_execute),
            ("test_execute_args", test_execute_args),
            ("test_execute_name", test_execute_name),
            ("test_execute_release", test_execute_release),
            ("test_help", test_help),
        ]
    }


    override func setUp() {
        TestSystem.reset()
    }


    // MARK: Tests


    func test_execute() {
        do {
            try Run.execute(with: [], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok(".build/debug/App ")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_args() {
        do {
            try Run.execute(with: ["foo", "-bar"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok(".build/debug/App foo -bar")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_name() {
        do {
            try Run.execute(with: ["--name=foo", "-bar"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok(".build/debug/foo -bar")])
        } catch {
            XCTFail("unexpected error")
        }

    }


    func test_execute_release() {
        do {
            try Run.execute(with: ["--release", "-bar"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok(".build/release/App -bar")])
        } catch {
            XCTFail("unexpected error")
        }
        
    }


    // FIXME: test exception code paths

    
    func test_help() {
        XCTAssert(Run.help.count > 0)
    }

}
