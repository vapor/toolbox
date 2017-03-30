import XCTest
@testable import VaporToolbox


class CleanTests: XCTestCase {
    static let allTests = [
        ("testClean", testClean),
        ("testCleanWithXcode", testCleanWithXcode),
        ("testCleanWithPins", testCleanWithPins)
    ]

    let console: TestConsole = .default()
    lazy var clean: Clean = Clean(console: self.console)

    func testClean() throws {
        try clean.run(arguments: [])
        XCTAssertEqual(console.outputBuffer, [
            "Cleaning [Done]"
            ])
        XCTAssertEqual(console.executeBuffer, [
            "rm -rf .build",
            ])
    }

    func testCleanWithXcode() throws {
        do {
            try clean.run(arguments: ["--xcode"])
            XCTAssertEqual(console.outputBuffer, [
                "Cleaning [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "rm -rf .build",
                "rm -rf *.xcodeproj"
            ])
        } catch {
            XCTFail("Clean failed: \(error)")
        }
    }

    func testCleanWithPins() {
        do {
            try clean.run(arguments: ["--pins"])
            XCTAssertEqual(console.outputBuffer, [
                "Cleaning [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "rm -rf .build",
                "rm -rf Package.pins"
            ])
        } catch {
            XCTFail("Clean failed: \(error)")
        }
    }
}
