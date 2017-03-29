import XCTest
import JSON
@testable import VaporToolbox

extension TestConsole {
    static func `default`() -> TestConsole {
        let console = TestConsole()

        // swift commands
        console.backgroundExecuteOutputBuffer["swift package --enable-prefetching fetch"] = ""
        console.backgroundExecuteOutputBuffer["swift package fetch"] = ""
        console.backgroundExecuteOutputBuffer["swift build --enable-prefetching"] = ""
        console.backgroundExecuteOutputBuffer["swift build"] = ""

        console.backgroundExecuteOutputBuffer["swift package dump-package"] = try! JSON(["name": "Hello"]).serialize().makeString()
        // find commands
        console.backgroundExecuteOutputBuffer["find ./Sources -type f -name main.swift"] =
        "~/Desktop/MyProject/Sources/Hello/main.swift"

        // ls commands
        console.backgroundExecuteOutputBuffer["ls .build/debug/Hello"] = ".build/debug/Hello\n"
        console.backgroundExecuteOutputBuffer["ls -a ."] = ""
        console.backgroundExecuteOutputBuffer["ls .build/debug"] = ""
        console.backgroundExecuteOutputBuffer["ls .build/release"] = ""
        console.backgroundExecuteOutputBuffer["ls .build/release/Hello"] = ".build/release/Hello\n"
        
        // rm commands
        console.backgroundExecuteOutputBuffer["rm -rf .build"] = ""
        console.backgroundExecuteOutputBuffer["rm -rf *.xcodeproj"] = ""
        console.backgroundExecuteOutputBuffer["rm -rf Package.pins"] = ""
        return console
    }
}
class BuildTests: XCTestCase {
    static let allTests = [
        ("testBuild", testBuild),
        ("testBuildAndClean", testBuildAndClean),
        ("testBuildAndRun", testBuildAndRun)
    ]

    let console: TestConsole = .default()
    lazy var build: Build = Build(console: self.console)

    func testBuild() throws {
        try build.run(arguments: ["--modulemap=false"])

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
    }

    func testBuildAndClean() throws {
        try build.run(arguments: ["--clean", "--modulemap=false"])

        XCTAssertEqual(console.outputBuffer, [
            "Cleaning [Done]",
            "No .build folder, fetch may take a while...",
            "Fetching Dependencies [Done]",
            "Building Project [Done]"
            ])
        XCTAssertEqual(console.executeBuffer, [
            "rm -rf .build",
            "ls -a .",
            "swift package --enable-prefetching fetch",
            "swift build --enable-prefetching",
            ])
    }

    func testBuildAndRun() throws {
        let name = "WallaWalla"
        console.backgroundExecuteOutputBuffer["swift package dump-package"] = "{\"name\": \"\(name)\"}"

        try build.run(arguments: ["--run", "--modulemap=false"])
        XCTAssertEqual(console.outputBuffer, [
            "No .build folder, fetch may take a while...",
            "Fetching Dependencies [Done]",
            "Building Project [Done]",
            "Running \(name) ..."
            ])
        XCTAssertEqual(console.executeBuffer, [
            "ls -a .",
            "swift package --enable-prefetching fetch",
            "swift build --enable-prefetching",
            "ls .build/debug",
            "swift package dump-package",
            "find ./Sources -type f -name main.swift",
            "ls .build/debug/Hello",
            ".build/debug/Hello"
            ])
    }
}
