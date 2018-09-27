import VaporToolbox
import XCTest

final class VaporToolboxTests: XCTestCase {
    func testNothing() throws {
        // add your tests here
        XCTAssert(true)
    }
    func testFail() throws {
        XCTAssert(false)
    }
}

var tests = [XCTestCaseEntry]()
tests += VaporToolboxTests.__allTests()
XCTMain(tests)
