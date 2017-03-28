import XCTest
@testable import VaporToolbox


class BuildTests: XCTestCase {
    static let allTests = [
        ("testBuild", testBuild),
        ("testBuildAndClean", testBuildAndClean),
        ("testBuildAndRun", testBuildAndRun)
    ]

    var console: TestConsole!
    var build: Build!

    override func setUp() {
        console = TestConsole()
        build = Build(console: console)

        // Default find commands
        console.backgroundExecuteOutputBuffer["find ./Sources -type f -name main.swift"] =
        "~/Desktop/MyProject/Sources/Hello/main.swift"
        console.backgroundExecuteOutputBuffer["ls .build/debug/Hello"] = ".build/debug/Hello\n"
        console.backgroundExecuteOutputBuffer["ls -a ."] = ".build Packages"
        console.backgroundExecuteOutputBuffer["swift package --enable-prefetching fetch"] = ""
        console.backgroundExecuteOutputBuffer["swift package fetch"] = ""
        console.backgroundExecuteOutputBuffer["swift build --enable-prefetching"] = ""
        console.backgroundExecuteOutputBuffer["swift build"] = ""
        console.backgroundExecuteOutputBuffer["ls .build/debug"] = ""
    }

    func testBuild() {
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

    func testBuildAndRun() throws {
        let name = "WallaWalla"
        console.backgroundExecuteOutputBuffer["swift package dump-package"] =
        "{\"name\": \"\(name)\"}"

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
        } catch ToolboxError.general(let error) where error == "No executables found" {}
        catch {
            print(" \(console.backgroundExecuteOutputBuffer)")
            print("Er: \(error)")
            print("")
        }
    }
}
