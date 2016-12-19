import XCTest
@testable import VaporToolbox

extension NewTests {
    static var allTests: [(String, (NewTests) -> () throws -> Void)] {
        return [
            ("testNew", testNew),
            ("testNewCustomTemplateWithName", testNewCustomTemplateWithName),
            ("testInvalidTemplateOption", testInvalidTemplateOption),
            ("testSignatureHelp", testSignatureHelp),
            ("testHelp", testHelp),
        ]
    }
}

class NewTests: XCTestCase {
    
    var console: TestConsole!
    var new: New!
    
    override func setUp() {
        console = TestConsole()
        new = New(console: console)
    }
    
    // MARK: Tests
    
    func testNew(){
        do {
            let name = "vapor-test"
            try new.run(arguments: ["\(name)"]
            )
            XCTAssertEqual(console.outputBuffer, defaultOutputBufferFor(name))
            XCTAssertEqual(console.executeBuffer, defaultExecuteBufferFor(name))
        } catch {
            XCTFail("New run failed: \(error)")
        }
    }
    
    func testNewCustomTemplateWithName(){
        do {
            let name = "light"
            try new.run(arguments: ["\(name)", "--template=\(name)"]
            )
            XCTAssertEqual(console.outputBuffer, defaultOutputBufferFor(name))
            XCTAssertEqual(console.executeBuffer, customExecuteBufferFor(name))
        } catch {
            XCTFail("New run failed: \(error)")
        }
    }
    
    func testInvalidTemplateOption(){
        do {
            let name = "light-template"
            try new.run(arguments: [
                "\(name)",
                "http://github.com/vapor/\(name)",
                "--template=true"
                ]
            )
            XCTAssertEqual(console.outputBuffer, [
                "Use --template=http://github.com/vapor/\(name) to define a template.\n"
                ]
            )
            XCTAssertNil(console.executeBuffer)
        } catch {
            XCTAssertEqual("\(error)", "general(\"Invalid template option\")")
        }
    }
    
    func testSignatureHelp(){
        new.printSignatureHelp()
        
        XCTAssertEqual(console.outputBuffer, signatureHelp())
        XCTAssert(console.executeBuffer == [])
    }
    
    func testHelp() {
        console.printHelp(executable: "executable", command: new)
        
        XCTAssertEqual(console.outputBuffer, [
            "Usage: executable new <name> [--template]",
            "Creates a new Vapor application from a template.",
            ]
            + signatureHelp()
        )
        XCTAssert(console.executeBuffer == [])
    }
    
    // FIXME: test without arguments
    // FIXME: test exception code paths
}

extension NewTests {
    fileprivate func defaultOutputBufferFor(_ name: String) -> [String]{
        return ["Cloning Template [Done]", ""]
            + new.asciiArt
            + [
                "",
                "Project \"\(name)\" has been created.",
                "Type `cd \(name)` to enter the project directory.",
                "Enjoy!",
                ""
        ]
    }
    
    fileprivate func defaultExecuteBufferFor(_ name: String) -> [String]{
        return [
            "git clone https://github.com/vapor/basic-template \(name)",
            "rm -rf \(name)/.git",
            "/bin/sh -c cat \(name)/Package.swift",
            "/bin/sh -c echo \"\" > \(name)/Package.swift"
        ]
    }
    
    fileprivate func customExecuteBufferFor(_ name: String) -> [String]{
        return [
            "curl -o /dev/null --silent --head --write-out \'%{http_code}\n\' \(name)",
            "curl -o /dev/null --silent --head --write-out \'%{http_code}\n\' https://github.com/vapor/\(name)",
            "git clone https://github.com/vapor/\(name)-template \(name)", "rm -rf \(name)/.git",
            "/bin/sh -c cat \(name)/Package.swift", "/bin/sh -c echo \"\" > \(name)/Package.swift"
        ]
    }
    
    fileprivate func signatureHelp() -> [String] {
        return [
            "    name: The application\'s executable name.",
            "template: The template repository to clone.",
            "          https://example.com/repo => https://example.com/repo",
            "          user/repo => https://github.com/user/repo",
            "          repo => https://github.com/vapor/repo",
            "          Default: https://github.com/vapor/basic-template.",
        ]
    }
    
}
