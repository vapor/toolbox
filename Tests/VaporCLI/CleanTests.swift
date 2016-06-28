//
//  CleanTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


//class CleanTests: XCTestCase {
//
//    // required by LinuxMain.swift
//    static var allTests: [(String, (CleanTests) -> () throws -> Void)] {
//        return [
//            ("test_execute", test_execute),
//        ]
//    }
//
//
//    override func setUp() {
//        // reset test shell
//        TestSystem.reset()
//    }
//
//
//    // MARK: Tests
//
//
//    func test_execute() {
//        let _ = try? Build.execute(with: [], in: TestSystem.shell)
//        XCTAssertEqual(TestSystem.log, [.ok("swift package fetch"), .ok("swift build ")])
//    }
//
//}
