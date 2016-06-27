//
//  CmdDockerTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI


var executed = [String]()
var shell = TestShell()


class CmdDockerTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (CmdDockerTests) -> () throws -> Void)] {
        return [
            ("test_subCommands", test_subCommands),
            ("test_execute_init", test_execute_init),
            ("test_execute_init_verbose", test_execute_init_verbose),
            ("test_execute_init_Dockerfile_exists", test_execute_init_Dockerfile_exists),
        ]
    }

    override func setUp() {
        // reset command history and test shell
        executed = [String]()
        shell = TestShell(onExecute: { cmd in executed.append(cmd) })
    }

    func test_subCommands() {
        let expected: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self, Docker.Enter.self]
        // map to String, because currently XCTAssert cannot compare Command.Type (doesn't find a suitable overload)
        XCTAssertEqual(Docker.subCommands.map {"\($0)"}, expected.map {"\($0)"})
    }

    func test_execute_init() {
        Docker.execute(with: ["init"], in: "", shell: shell)
        XCTAssertEqual(executed, ["curl -L -s docker.qutheory.io -o Dockerfile"])
    }

    func test_execute_init_verbose() {
        Docker.execute(with: ["init", "--verbose"], in: "", shell: shell)
        XCTAssertEqual(executed, ["curl -L  docker.qutheory.io -o Dockerfile"])
    }

    func test_execute_init_Dockerfile_exists() {
        shell.fileExists = true
        Docker.execute(with: ["init"], in: "", shell: shell)
        XCTAssertEqual(executed, [])
    }

}
