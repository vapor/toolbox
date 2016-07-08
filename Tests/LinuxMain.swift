import XCTest
@testable import VaporToolboxTestSuite

XCTMain([
    testCase(BuildTests.allTests),
    testCase(CleanTests.allTests),
    testCase(StringExtTests.allTests),
])
