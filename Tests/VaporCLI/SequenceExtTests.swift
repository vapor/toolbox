//
//  SequenceExt.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI

class SequenceExtTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (SequenceExtTests) -> () throws -> Void)] {
        return [
            ("test_valueFor", test_valueFor),
        ]
    }

    func test_valueFor() {
        let args = ["--name=foo", "--debug"]
        XCTAssertEqual(args.valueFor(argument: "name"), Optional("foo"))
        XCTAssertNil(args.valueFor(argument: "debug"))
    }

}
