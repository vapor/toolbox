import XCTest
@testable import VaporToolbox

class StringExtTests: XCTestCase {
    static var allTests = [
        ("testTrim", testTrim)
    ]

    func testTrim() {
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
}
