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
            ("test_init", test_init),
            ("test_init_verbose", test_init_verbose),
            ("test_init_Dockerfile_exists", test_init_Dockerfile_exists),
            ("test_init_download_failure", test_init_download_failure),
            ("test_init_help", test_init_help),
        ]
    }

    override func setUp() {
        // reset command history and test shell
        log = [LogEntry]()
        shell = TestShell(logEvent: { log.append($0) })
    }

    // MARK: Tests - General

    func test_subCommands() {
        let expected: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self, Docker.Enter.self]
        // map to String, because currently XCTAssert cannot compare Command.Type (doesn't find a suitable overload)
        XCTAssertEqual(Docker.subCommands.map {"\($0)"}, expected.map {"\($0)"})
    }

    // MARK: Init subcommmand

    func test_init() {
        let _ = try? Docker.execute(with: ["init"], in: shell)
        let expected: [LogEntry] = [.ok("curl -L -s docker.qutheory.io -o Dockerfile")]
        XCTAssertEqual(log, expected)
    }

    func test_init_verbose() {
        let _ = try? Docker.execute(with: ["init", "--verbose"], in: shell)
        XCTAssertEqual(log, [.ok("curl -L  docker.qutheory.io -o Dockerfile")])
    }

    func test_init_Dockerfile_exists() {
        shell.fileExists = true
        do {
            try Docker.execute(with: ["init"], in: shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssert(msg.hasPrefix("A Dockerfile already exists"))
            XCTAssertEqual(log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }

    func test_init_download_failure() {
        shell.commandResults = { cmd in
            if cmd.hasPrefix("curl") {
                // fake a "Failed to connect to host" error
                return .error(7)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Docker.execute(with: ["init"], in: shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "Could not download Dockerfile.")
            XCTAssertEqual(log, [.error(7)])
        } catch {
            XCTFail("unexpected error")
        }
    }

    func test_init_help() {
        XCTAssert(Docker.Init.help.count > 0)
    }
}
