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
        TestShell.reset()
    }


    // MARK: Tests


    func test_execute() {
        let _ = try? Build.execute(with: [], in: TestShell.shell)
        XCTAssertEqual(TestShell.log, [.ok("swift package fetch"), .ok("swift build ")])
    }

    
    func test_execute_args() {
        let _ = try? Build.execute(with: ["-foo", "-bar"], in: TestShell.shell)
        XCTAssertEqual(TestShell.log, [.ok("swift package fetch"), .ok("swift build -foo -bar")])
    }


    func test_execute_release() {
        let _ = try? Build.execute(with: ["--release"], in: TestShell.shell)
        XCTAssertEqual(TestShell.log, [.ok("swift package fetch"), .ok("swift build -c release")])
    }


    func test_help() {
        XCTAssert(Build.help.count > 0)
    }

}
