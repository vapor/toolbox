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
            try build.run(arguments: ["--modulemap=false"])
            #if swift(>=3.1)
                XCTAssertEqual(console.outputBuffer, [
                    "No .build folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]"
                ])
                XCTAssertEqual(console.executeBuffer, [
                    "ls -a .",
                    "swift package --enable-prefetching fetch",
                    "swift build --enable-prefetching",
                ])
            #else
                XCTAssertEqual(console.outputBuffer, [
                    "No Packages folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]"
                    ])
                XCTAssertEqual(console.executeBuffer, [
                    "ls -a .",
                    "swift package fetch",
                    "swift build",
                    ])
            #endif
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }

    func testBuildAndClean() {
        let console = TestConsole()
        let build = Build(console: console)

        do {
            try build.run(arguments: ["--clean", "--modulemap=false"])

            #if swift(>=3.1)
                XCTAssertEqual(console.outputBuffer, [
                    "Cleaning [Done]",
                    "No .build folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]"
                ])
                XCTAssertEqual(console.executeBuffer, [
                    "rm -rf Packages .build",
                    "ls -a .",
                    "swift package --enable-prefetching fetch",
                    "swift build --enable-prefetching",
                ])
            #else
                XCTAssertEqual(console.outputBuffer, [
                    "Cleaning [Done]",
                    "No Packages folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]"
                    ])
                XCTAssertEqual(console.executeBuffer, [
                    "rm -rf Packages .build",
                    "ls -a .",
                    "swift package fetch",
                    "swift build",
                    ])

            #endif
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
            try build.run(arguments: ["--run", "--modulemap=false"])
            #if swift(>=3.1)
                XCTAssertEqual(console.outputBuffer, [
                    "No .build folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]",
                    "Running \(name)..."
                ])
                XCTAssertEqual(console.executeBuffer, [
                    "ls -a .",
                    "swift package --enable-prefetching fetch",
                    "swift build --enable-prefetching",
                    "ls .build/debug",
                    "swift package dump-package",
                    ".build/debug/App"
                ])
            #else
                XCTAssertEqual(console.outputBuffer, [
                    "No Packages folder, fetch may take a while...",
                    "Fetching Dependencies [Done]",
                    "Building Project [Done]",
                    "Running \(name)..."
                    ])
                XCTAssertEqual(console.executeBuffer, [
                    "ls -a .",
                    "swift package fetch",
                    "swift build",
                    "ls .build/debug",
                    "swift package dump-package",
                    ".build/debug/App"
                    ])
            #endif
        } catch {
            XCTFail("Build run failed: \(error)")
        }
    }
}
