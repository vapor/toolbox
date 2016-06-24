//
//  UtilsTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI


struct TestShell: PosixSubsystem {
    let execute: (String) -> ()

    func system(_ command: String) -> Int32 {
        self.execute(command)
        return 0
    }
}


class UtilsTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (UtilsTests) -> () throws -> Void)] {
        return [
            ("test_getCommand", test_getCommand),
        ]
    }

    // FIXME: most functions in Utils.swift are currently very hard or impossible to test
    func test_ShellCommand() {
        var executed = [String]()
        let shell = TestShell(execute: { command in
            executed.append(command)
        })
        let res = try? "ls -l".run(runner: shell)
        XCTAssertEqual(res, 0)
        XCTAssertEqual(executed, ["ls -l"])
    }

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
