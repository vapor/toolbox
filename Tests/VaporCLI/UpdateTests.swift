//
//  UpdateTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI

class UpdateTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (UpdateTests) -> () throws -> Void)] {
        return [
            ("test_pathToSelf", test_pathToSelf),
            ("test_execute", test_execute),
            ("test_execute_verbose", test_execute_verbose),
            ("test_execute_args", test_execute_args),
            ("test_help", test_help),
        ]
    }


    override func setUp() {
        // reset test shell
        TestSystem.reset()
        Update._argumentsProvider = TestProcess.self
        TestProcess.arguments = ["PATH/vapor"]
    }


    // MARK: Tests


    func test_pathToSelf() {
        TestProcess.arguments = ["/usr/local/bin/vapor"]
        XCTAssertEqual(Update.pathToSelf, "/usr/local/bin/vapor")

        // FIXME: enable after making `runWithOutput` testable in TestSystem
        //        TestProcess.arguments = ["vapor"]
        //        XCTAssertEqual(Update.pathToSelf, "/somepath/vapor")
    }


    func test_execute() {
        do {
            try Update.execute(with: [], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [
                .ok("curl -L -s vapor-cli.qutheory.io -o vapor-install.swift"),
                .ok("swift vapor-install.swift PATH/vapor")
                ])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_verbose() {
        do {
            try Update.execute(with: ["--verbose"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [
                .ok("curl -L  vapor-cli.qutheory.io -o vapor-install.swift"),
                .ok("swift vapor-install.swift PATH/vapor")
                ])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_execute_args() {
        do {
            try Update.execute(with: ["foo", "-bar"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [
                .ok("curl -L -s vapor-cli.qutheory.io -o vapor-install.swift"),
                .ok("swift vapor-install.swift PATH/vapor")
                ])
        } catch {
            XCTFail("unexpected error")
        }
    }


    // FIXME: test exception code paths


    func test_help() {
        XCTAssert(Update.help.count > 0)
    }

}
