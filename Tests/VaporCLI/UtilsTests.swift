//
//  UtilsTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI

class UtilsTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (UtilsTests) -> () throws -> Void)] {
        return [
            ("test_getCommand", test_getCommand),
        ]
    }

    // FIXME: most functions in Utils.swift are currently very hard or impossible to test

    func test_getCommand() {
        let cmds: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self]
        if let res = getCommand(id: "init", commands: cmds) {
            // XCTAssertEqual cannot compare Command.Type, need to coerce to string
            XCTAssertEqual("\(res)", "\(Docker.Init.self)")
        } else {
            XCTFail()
        }
    }

}
