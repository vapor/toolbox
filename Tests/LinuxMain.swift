import XCTest

@testable import VaporToolboxTests

extension VaporToolboxTests {
    static let __allTests = [
        ("testNothing", testNothing),
        ("testFail", testFail),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(VaporToolboxTests.__allTests),
    ]
}

var tests = [XCTestCaseEntry]()
tests += __allTests()

XCTMain(tests)
#endif
