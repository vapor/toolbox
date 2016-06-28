//
//  DockerTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI


class DockerTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (DockerTests) -> () throws -> Void)] {
        return [
            ("test_subCommands", test_subCommands),
            ("test_swiftVersion", test_swiftVersion),
            ("test_imageName", test_imageName),
            ("test_init", test_init),
            ("test_init_verbose", test_init_verbose),
            ("test_init_Dockerfile_exists", test_init_Dockerfile_exists),
            ("test_init_download_failure", test_init_download_failure),
            ("test_init_help", test_init_help),
            ("test_build", test_build),
            ("test_build_help", test_build_help),
            ("test_run", test_run),
            ("test_run_help", test_run_help),
            ("test_enter", test_enter),
            ("test_enter_help", test_enter_help),
        ]
    }


    override func setUp() {
        // reset test shell
        TestSystem.reset()
    }


    // MARK: Tests - General


    func test_subCommands() {
        let expected: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self, Docker.Enter.self]
        // map to String, because currently XCTAssert cannot compare Command.Type (doesn't find a suitable overload)
        XCTAssertEqual(Docker.subCommands.map {"\($0)"}, expected.map {"\($0)"})
    }


    func test_swiftVersion() {
        Docker._swiftVersionFile = TestFile(contents: "version\n")
        XCTAssertEqual(Docker.swiftVersion(), "version")
    }


    func test_imageName() {
        Docker._swiftVersionFile = TestFile(contents: "v2\n")
        XCTAssertEqual(Docker.imageName(), Optional("qutheory/swift:v2"))
    }

    
    // MARK: Init subcommmand


    func test_init() {
        do {
            try Docker.execute(with: ["init"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("curl -L -s docker.qutheory.io -o Dockerfile")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_init_verbose() {
        do {
            try Docker.execute(with: ["init", "--verbose"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("curl -L  docker.qutheory.io -o Dockerfile")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_init_Dockerfile_exists() {
        TestSystem.shell.fileExists = true
        do {
            try Docker.execute(with: ["init"], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssert(msg.hasPrefix("A Dockerfile already exists"))
            XCTAssertEqual(TestSystem.log, [], "expected no commands to be run")
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_init_download_failure() {
        TestSystem.shell.commandResults = { cmd in
            if cmd.hasPrefix("curl") {
                // fake a "Failed to connect to host" error
                return .error(7)
            } else {
                return .ok(cmd)
            }
        }
        do {
            try Docker.execute(with: ["init"], in: TestSystem.shell)
            XCTFail("should not be reached, expected error to be thrown")
        } catch Error.failed(let msg) {
            XCTAssertEqual(msg, "Could not download Dockerfile.")
            XCTAssertEqual(TestSystem.log, [.error(7)])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_init_help() {
        XCTAssert(Docker.Init.help.count > 0)
    }


    // MARK: Build subcommand


    func test_build() {
        Docker._swiftVersionFile = TestFile(contents: "v1")
        do {
            try Docker.execute(with: ["build"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("docker build --rm -t qutheory/swift:v1 --build-arg SWIFT_VERSION=v1 .")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_build_help() {
        XCTAssert(Docker.Build.help.count > 0)
    }


    // MARK: Run subcommand


    func test_run() {
        Docker._swiftVersionFile = TestFile(contents: "v1")
        do {
            try Docker.execute(with: ["run"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("docker run --rm -it -v $(PWD):/vapor -p 8080:8080 qutheory/swift:v1")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_run_help() {
        XCTAssert(Docker.Run.help.count > 0)
    }


    // MARK: Enter subcommand


    func test_enter() {
        Docker._swiftVersionFile = TestFile(contents: "v1")
        do {
            try Docker.execute(with: ["enter"], in: TestSystem.shell)
            XCTAssertEqual(TestSystem.log, [.ok("docker run --rm -it -v $(PWD):/vapor --entrypoint bash qutheory/swift:v1")])
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_enter_help() {
        XCTAssert(Docker.Enter.help.count > 0)
    }
    
}
