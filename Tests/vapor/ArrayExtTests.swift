import XCTest
@testable import vapor

class ArrayExtTests: XCTestCase {
    // required by LinuxMain.swift
    static var allTests: [(String, (ArrayExtTests) -> () throws -> Void)] {
        return [
                   ("testRemove", testRemove),
        ]
    }

    func testRemove() {
        var a = ["a", "b", "c"]
        a.remove("b")
        XCTAssertEqual(a.count, 2)
    }
    
}
