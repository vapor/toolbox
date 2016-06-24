import XCTest
@testable import VaporCLITestSuite

XCTMain([
    testCase(ArrayExtTests.allTests),
    testCase(CmdDockerTests.allTests),
    testCase(SequenceExt.allTests),
])
