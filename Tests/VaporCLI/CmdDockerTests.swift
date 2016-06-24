//
//  CmdDockerTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI

class CmdDockerTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (CmdDockerTests) -> () throws -> Void)] {
        return [
            ("test_subCommands", test_subCommands),
        ]
    }

    func test_subCommands() {
        let expected: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self, Docker.Enter.self]
        // map to String, because currently XCTAssert cannot compare Command.Type (doesn't find a suitable overload)
        XCTAssertEqual(Docker.subCommands.map {"\($0)"}, expected.map {"\($0)"})
    }

}
