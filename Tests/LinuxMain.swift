import XCTest
@testable import VaporCLITestSuite

XCTMain([
    testCase(ArrayExtTests.allTests),
    testCase(BuildTests.allTests),
    testCase(CleanTests.allTests),
    testCase(DockerTests.allTests),
    testCase(NewTests.allTests),
    testCase(RunTests.allTests),
    testCase(SequenceExtTests.allTests),
    testCase(StringExtTests.allTests),
    testCase(UpdateTests.allTests),
    testCase(UtilsTests.allTests),
])
