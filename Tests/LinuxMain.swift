import XCTest
@testable import VaporToolboxTests

XCTMain([
    testCase(BuildTests.allTests),
    testCase(CleanTests.allTests),
    testCase(RunTests.allTests),
    testCase(StringExtTests.allTests),
    testCase(VaporConfigFlagsTests.allTests),
])
