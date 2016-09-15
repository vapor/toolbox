import XCTest
@testable import VaporToolbox


class BuildTests: XCTestCase {
    static let allTests = [
        ("testBuild", testBuild),
        ("testBuildAndClean", testBuildAndClean),
        ("testBuildAndRun", testBuildAndRun)
    ]

    func testBuild() {
        let console = TestConsole()
        let build = Build(console: console)

        do {
            try build.run(arguments: [])
            XCTAssertEqual(console.outputBuffer, [
                "No Packages folder, fetch may take a while...",
                "Fetching Dependencies [Done]",
                "Building Project [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "ls .",
                "swift package fetch",
                "swift build",
            ])
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }

    func testBuildAndClean() {
        let console = TestConsole()
        let build = Build(console: console)

        do {
            try build.run(arguments: ["--clean"])
            XCTAssertEqual(console.outputBuffer, [
                "Cleaning [Done]",
                "No Packages folder, fetch may take a while...",
                "Fetching Dependencies [Done]",
                "Building Project [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "rm -rf Packages .build",
                "ls .",
                "swift package fetch",
                "swift build",
            ])
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }

    func testBuildAndRun() {
        let console = TestConsole()
        let build = Build(console: console)

        let name = "TestName"
        console.backgroundExecuteOutputBuffer = [
            "swift package dump-package": "{\"name\": \"\(name)\"}"
        ]

        do {
            try build.run(arguments: ["--run"])
            XCTAssertEqual(console.outputBuffer, [
                "No Packages folder, fetch may take a while...",
                "Fetching Dependencies [Done]",
                "Building Project [Done]",
                "Running \(name)..."
            ])
            XCTAssertEqual(console.executeBuffer, [
                "ls .",
                "swift package fetch",
                "swift build",
                "ls .build/debug",
                "swift package dump-package",
                ".build/debug/\(name)"
            ])
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }

    func testBuildWithMySQL() {
        let console = TestConsole()
        let build = Build(console: console)

        do {
            try build.run(arguments: ["--mysql"])
            XCTAssertEqual(console.outputBuffer, [
                "No Packages folder, fetch may take a while...",
                "Fetching Dependencies [Done]",
                "Building Project [Done]"
            ])
            XCTAssertEqual(console.executeBuffer, [
                "ls .",
                "swift package fetch",
                "swift build -Xswiftc -I/usr/local/include/mysql -Xlinker -L/usr/local/lib",
            ])
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }
}
