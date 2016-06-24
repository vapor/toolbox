//
//  StringExtTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI

class StringExtTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (StringExtTests) -> () throws -> Void)] {
        return [
            ("test_trim", test_trim),
            ("test_centerTextBlock", test_centerTextBlock),
            ("test_colored", test_colored),
        ]
    }

    func test_trim() {
        let spaces = " abc "
        let tabs = "\tabc\t"
        let newlines = "\nabc\n"
        let carriageReturns = "\rabc\r"
        let whiteSpace = " \t\n\rabc \t\n\r"
        XCTAssertEqual(spaces.trim(), "abc")
        XCTAssertEqual(tabs.trim(), "abc")
        XCTAssertEqual(newlines.trim(), "abc")
        XCTAssertEqual(carriageReturns.trim(), "abc")
        XCTAssertEqual(whiteSpace.trim(), "abc")
        XCTAssertEqual(spaces.trim(characters: ["\t"]), spaces)
        XCTAssertEqual(whiteSpace.trim(characters: [" ", "\r"]), "\t\n\rabc \t\n")
    }

    func test_centerTextBlock() {
        XCTAssertEqual("abc".centerTextBlock(width: 4), "abc")
        XCTAssertEqual("abc".centerTextBlock(width: 5), " abc")
        XCTAssertEqual("abc".centerTextBlock(width: 6), " abc")
        XCTAssertEqual("abc".centerTextBlock(width: 7), "  abc")
        XCTAssertEqual("abc".centerTextBlock(width: 7, paddingCharacter: "="), "==abc")
        XCTAssertEqual("abc\nde\nf".centerTextBlock(width: 7), "  abc\n  de\n  f")
    }

    func test_colored() {
        let black = "\u{001B}[0;30m"
        let red = "\u{001B}[0;31m"
        let reset = "\u{001B}[0;0m"
        XCTAssertEqual("abc".colored(with: .black), "\(black)abc\(reset)")
        XCTAssertEqual("abc".colored(with: ["a": .black, "c": .red]), "\(black)a\(reset)b\(red)c\(reset)")
    }

}
