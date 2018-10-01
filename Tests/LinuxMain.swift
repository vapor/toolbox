import XCTest

@testable import VaporToolboxTests

// MARK: VaporToolboxTests

extension VaporToolboxTests.VaporToolboxTests0 {
    static let __allTests = [
        ("testNothing", testNothing),
        ("testFail", testFail),
        ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(VaporToolboxTests.VaporToolboxTests0.__allTests),
    ]
}

let tests = __allTests()
XCTMain(tests)
#endif
