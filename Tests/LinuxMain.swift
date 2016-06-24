import XCTest
@testable import VaporCLITestSuite

XCTMain([
    testCase(ArrayExtTests.allTests),
    testCase(CmdDockerTests.allTests),
    testCase(SequenceExtTests.allTests),
    testCase(StringExtTests.allTests),
    testCase(UtilsTests.allTests),
])
