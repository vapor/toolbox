import XCTest
@testable import VaporToolbox


class CleanTests: XCTestCase {
    static let allTests = [
        ("testClean", testClean),
        ("testCleanWithXcode", testCleanWithXcode)
    ]

    func testClean() {
        let console = TestConsole()
        let clean = Clean(console: console)

        do {
            try clean.run(arguments: [])
            XCTAssertEqual(console.outputBuffer, [
                "Cleaning [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "rm -rf Packages .build",
            ])
        } catch {
            XCTFail("Clean failed: \(error)")
        }
    }

    func testCleanWithXcode() {
        let console = TestConsole()
        let clean = Clean(console: console)

        do {
            try clean.run(arguments: ["--xcode"])
            XCTAssertEqual(console.outputBuffer, [
                "Cleaning [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "rm -rf Packages .build",
                "rm -rf *.xcodeproj"
            ])
        } catch {
            XCTFail("Clean failed: \(error)")
        }
    }
}
