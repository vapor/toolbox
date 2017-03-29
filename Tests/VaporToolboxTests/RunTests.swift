import XCTest
import JSON
@testable import VaporToolbox

class RunTests: XCTestCase {
    // required by LinuxMain.swift
    static var allTests: [(String, (RunTests) -> () throws -> Void)] {
        return [
            ("testRunFailsWithNoInformation", testRunFailsWithNoInformation),
            ("testRunNameResolution", testRunNameResolution),
            ("testRunNameResolutionWithTargets", testRunNameResolutionWithTargets),
            ("testRunWithProvidedExec", testRunWithProvidedExec),
            ("testRunRelease", testRunRelease),
            ("testRunArgumentPassthrough", testRunArgumentPassthrough)
        ]
    }

    var console: TestConsole = .default()
    lazy var command: Run = Run(console: self.console)

    override func setUp() {
        // Default find commands
//        console.backgroundExecuteOutputBuffer["find ./Sources -type f -name main.swift"] =
//        "~/Desktop/MyProject/Sources/Hello/main.swift"
//        console.backgroundExecuteOutputBuffer["ls .build/debug/Hello"] = ".build/debug/Hello\n"
    }

    // MARK: Tests
    func testRunFailsWithNoInformation() throws {
        console.backgroundExecuteOutputBuffer["swift package dump-package"] = "non-json garbage"
        do {
            try command.run(arguments: [])
            XCTFail("command.run was expected to fail, but did not")
        } catch ToolboxError.general(let message) where message == "Unable to determine package name." {
            // error thrown is expected :+1:
        }
    }
    
    func testRunNameResolution() throws {
        try command.run(arguments: [])
        // TODO: the safeguard in Run uses FileManager.default that cannot be faked in the test,
        //       therefore the actual executed command cannot be tested.
        XCTAssertEqual("Running Hello ...", console.outputBuffer.last ?? "")
    }

    func testRunNameResolutionWithTargets() throws {
        console.backgroundExecuteOutputBuffer["swift package dump-package"] =
        "{\"dependencies\":[],\"exclude\":[],\"name\":\"MultiTargetApp\",\"targets\":[{\"dependencies\":[\"MultiTargetDependency\"],\"name\":\"App\"}]}"

        try command.run(arguments: [])
        
        // TODO: the safeguard in Run uses FileManager.default that cannot be faked in the test,
        //       therefore the actual executed command cannot be tested.
        XCTAssertEqual(
            "Running MultiTargetApp ...",
            console.outputBuffer.last
        )
    }

    func testRunWithProvidedExec() throws {
        console.backgroundExecuteOutputBuffer["ls .build/debug/Foo"] = ".build/debug/Foo\n"
        console.backgroundExecuteOutputBuffer[".build/debug/Foo"] = ""

        try command.run(arguments: ["--exec=Foo"])
        XCTAssertTrue(console.executeBuffer.last?.contains(".build/debug/Foo") ?? false)
    }
    
    func testRunRelease() throws {
        try command.run(arguments: ["--release"])
        XCTAssertTrue(console.executeBuffer.last?.contains(".build/release/") ?? false)
    }
    
    func testRunArgumentPassthrough() throws {
        try command.run(arguments: ["--name=Hello", "--foo=bar"])
        XCTAssertTrue(console.executeBuffer.last?.contains("--foo=bar") ?? false)
    }
}
