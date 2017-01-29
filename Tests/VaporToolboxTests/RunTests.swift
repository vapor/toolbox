import XCTest
@testable import VaporToolbox

class RunTests: XCTestCase {
    var console: TestConsole!
    var command: Run!
    
    // required by LinuxMain.swift
    static var allTests: [(String, (RunTests) -> () throws -> Void)] {
        return [
            ("testRunFailsWithNoInformation", testRunFailsWithNoInformation),
            ("testRunNameResolution", testRunNameResolution),
            ("testRunNameResolutionWithTargets", testRunNameResolutionWithTargets),
            ("testRunWithProvidedExec", testRunWithProvidedExec),
            ("testRunWithProvidedName", testRunWithProvidedName),
            ("testRunRelease", testRunRelease),
            ("testRunArgumentPassthrough", testRunArgumentPassthrough)
        ]
    }

    override func setUp() {
        console = TestConsole()
        command = Run(console: console)
    }

    // MARK: Tests
    func testRunFailsWithNoInformation() throws {
        do {
            try command.run(arguments: [])
        } catch (let err) {
            guard case ToolboxError.general(let message) = err else {
                XCTFail("command.run was expected to throw a general ToolboxError")
                throw err
            }

            XCTAssertEqual("Unable to determine package name.", message,
                           "Unexpected error was returned from command.run")
            return
        }
        
        XCTFail("command.run was expected to fail, but did not")
    }
    
    func testRunNameResolution() throws {
        console.backgroundExecuteOutputBuffer["swift package dump-package"] = "{\"dependencies\": [{\"url\": \"https://github.com/vapor/vapor.git\", \"version\": {\"lowerBound\": \"1.3.0\", \"upperBound\": \"1.3.9223372036854775807\"}}], \"exclude\": [\"Config\", \"Database\", \"Localization\", \"Public\", \"Resources\", \"Tests\"], \"name\": \"Hello\", \"targets\": []}"
        try command.run(arguments: [])

        // TODO: the safeguard in Run uses FileManager.default that cannot be faked in the test,
        //       therefore the actual executed command cannot be tested.
        XCTAssertEqual("Running Hello...", console.outputBuffer.last ?? "")
    }

    func testRunNameResolutionWithTargets() throws {
        console.backgroundExecuteOutputBuffer["swift package dump-package"] = "{\"dependencies\":[],\"exclude\":[],\"name\":\"MultiTargetApp\",\"targets\":[{\"dependencies\":[\"MultiTargetDependency\"],\"name\":\"App\"}]}"
        try command.run(arguments: [])
        
        // TODO: the safeguard in Run uses FileManager.default that cannot be faked in the test,
        //       therefore the actual executed command cannot be tested.
        XCTAssertEqual("Running MultiTargetApp...", console.outputBuffer.last ?? "")
    }

    func testRunWithProvidedExec() throws {
        try command.run(arguments: ["--exec=Hello", "--name=Hello"])
        XCTAssertTrue(console.executeBuffer.last?.contains(".build/debug/Hello") ?? false)
    }
    
    func testRunWithProvidedName() throws {
        try command.run(arguments: ["--name=Hello"])
        // TODO: the safeguard in Run uses FileManager.default that cannot be faked in the test,
        //       therefore the actual executed command cannot be tested.
        XCTAssertEqual("Running Hello...", console.outputBuffer.last ?? "")
    }
    
    func testRunRelease() throws {
        try command.run(arguments: ["--name=Hello", "--release"])
        XCTAssertTrue(console.executeBuffer.last?.contains(".build/release/") ?? false)
    }
    
    func testRunArgumentPassthrough() throws {
        try command.run(arguments: ["--name=Hello", "--foo=bar"])
        XCTAssertTrue(console.executeBuffer.last?.contains("--foo=bar") ?? false)
    }
}
