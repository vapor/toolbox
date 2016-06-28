import XCTest
@testable import VaporCLITestSuite

XCTMain([
    testCase(ArrayExtTests.allTests),
    testCase(DockerTests.allTests),
    testCase(SequenceExtTests.allTests),
    testCase(StringExtTests.allTests),
    testCase(UtilsTests.allTests),
])
