//
//  NewTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class NewTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (NewTests) -> () throws -> Void)] {
        return [
            ("test_execute", test_execute),
            ("test_execute_noargs", test_execute_noargs),
            ("test_help", test_help),
        ]
    }


    override func setUp() {
        TestSystem.reset()
    }


    // MARK: Tests


    func test_execute() {
        do {
            try New.execute(with: ["name"], in: TestSystem.shell)
            var expected: [LogEntry] = [
                .ok("mkdir \"name\""),
                .ok("curl -L -s https://github.com/qutheory/vapor-example/archive/master.tar.gz -o \"name\"/vapor-example.tar.gz"),
                .ok("tar -xzf \"name\"/vapor-example.tar.gz --strip-components=1 --directory \"name\""),
                .ok("rm \"name\"/vapor-example.tar.gz"),
                ]
            #if os(OSX)
                expected.append(.ok("cd \"name\" && vapor xcode"))
            #endif
            expected.append(.ok("git init \"name\""))
            expected.append(.ok("cd \"name\" && git add . && git commit -m \"initial vapor project setup\""))
            #if os(OSX)
               expected.append(.ok("open \"name\"/*.xcodeproj"))
            #endif
            // compare sizes and individual items separately to make result more readable in case of failure
            XCTAssertEqual(TestSystem.log.count, expected.count)
            for i in 0..<min(TestSystem.log.count, expected.count) {
                XCTAssertEqual(TestSystem.log[i], expected[i])
            }
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_noargs() {
        do {
            try New.execute(with: [], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "Invalid number of arguments.")
            XCTAssertEqual(TestSystem.log, [])
        } catch {
            XCTFail("unexpected error")
        }
    }


    // FIXME: test exception code paths


    func test_help() {
        XCTAssert(New.help.count > 0)
    }

}
