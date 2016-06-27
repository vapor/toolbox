//
//  CmdDockerTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI


var log = [LogEntry]()
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
        log = [LogEntry]()
        shell = TestShell(logEvent: { log.append($0) })
    }

    func test_subCommands() {
        let expected: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self, Docker.Enter.self]
        // map to String, because currently XCTAssert cannot compare Command.Type (doesn't find a suitable overload)
        XCTAssertEqual(Docker.subCommands.map {"\($0)"}, expected.map {"\($0)"})
    }

    func test_execute_init() {
        Docker.execute(with: ["init"], in: "", shell: shell)
        let expected: [LogEntry] = [.ok("curl -L -s docker.qutheory.io -o Dockerfile")]
        XCTAssertEqual(log, expected)
    }

    func test_execute_init_verbose() {
        Docker.execute(with: ["init", "--verbose"], in: "", shell: shell)
        XCTAssertEqual(log, [.ok("curl -L  docker.qutheory.io -o Dockerfile")])
    }

    func test_execute_init_Dockerfile_exists() {
        shell.fileExists = true
        Docker.execute(with: ["init"], in: "", shell: shell)
        XCTAssertEqual(log, [.failed("A Dockerfile already exists in the current directory.\nPlease move it and try again or run `vapor docker build`.")])
    }

}
