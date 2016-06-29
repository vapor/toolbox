//
//  ArrayExtTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 23/06/2016.
//
//

import XCTest
@testable import VaporCLI

class ArrayExtTests: XCTestCase {
    
    // required by LinuxMain.swift
    static var allTests: [(String, (ArrayExtTests) -> () throws -> Void)] {
        return [
            ("test_remove", test_remove),
            ("test_removeMatching", test_removeMatching),
        ]
    }

    func test_remove() {
        var a = ["a", "b", "c"]
        a.remove("b")
        XCTAssertEqual(a, ["a", "c"])
    }

    func test_removeMatching() {
        var a = ["a", "b", "c", "d"]
        let exclude = ["b", "d"]
        a.remove(matching: {exclude.contains($0)})
        XCTAssertEqual(a, ["a", "c"])
    }
}
