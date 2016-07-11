/*


//
//  HelpTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class HelpTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (HelpTests) -> () throws -> Void)] {
        return [
            ("test_execute", test_execute),
        ]
    }

    func test_execute() {
        // not much to test here beyond running the command (could revisit if we've got a mechanism to capture stdout)
        Help.execute(with: [], in: TestSystem.shell)
    }

}
 
 */
