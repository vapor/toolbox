@testable import VaporToolbox
import XCTest

final class VaporToolboxTests: XCTestCase {
    
    func testStub() throws {
        XCTAssertTrue(true)
    }
    
    /// Assures that when Swift version can be detected it produces the right result.
    /// - Note: As this test relies on conditional compilation it can only test one specific version (the one which is currently compiling the test).
    func testSwiftVersionDetection() throws {
        if let version = RuntimeSwiftVersion() {
#if swift(>=5.5)
            XCTAssertTrue(version.major > 5 || (version.major == 5 && version.minor >= 5))
#elseif swift(>=5.4)
            XCTAssertTrue(version.major == 5 && version.minor == 4)
#elseif swift(>=5.3)
            XCTAssertTrue(version.major == 5 && version.minor == 3)
#elseif swift(>=5.2)
            XCTAssertTrue(version.major == 5 && version.minor == 2)
#else
            XCTAssertTrue( !(version.major > 5 || (version.major == 5 && version.minor >= 2)))
#endif
        } else {
            // Swift version detection may fail but it doesn't cause any wrong result then it should pass the test.
            XCTAssertTrue(true)
        }
    }
    
}
