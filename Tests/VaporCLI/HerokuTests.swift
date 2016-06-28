//
//  HerokuTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 28/06/2016.
//
//

import XCTest
@testable import VaporCLI


class HerokuTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (HerokuTests) -> () throws -> Void)] {
        return [
            ("test_init", test_init),
            ("test_init_help", test_init_help),
        ]
    }


    override func setUp() {
        TestSystem.reset()
        Heroku._packageFile = TestFile(contents: "name: \"foo\"")
    }


    // MARK: Tests - General


    func test_getPackageName() {
        
    }


    // MARK: Init subcommmand


    func test_init() {
        do {
            try Heroku.execute(with: ["init"], in: TestSystem.shell)
            var expected: [LogEntry] = [
                .ok("git status --porcelain"),
                .ok("test -z \"$(git status --porcelain)\" || exit 1"),
                .ok("git remote show heroku"),
                .ok("heroku buildpacks:set https://github.com/kylef/heroku-buildpack-swift"),
                .ok("echo \"web: App --port=\\$PORT\" > ./Procfile"),
                .ok("git add ."),
                .ok("git commit -m \"setting up heroku\""),
                .ok("git push heroku master"),
                .ok("heroku ps:scale web=1"),
            ]
            // compare sizes and individual items separately to make result more readable in case of failure
            XCTAssertEqual(TestSystem.log.count, expected.count)
            for i in 0..<min(TestSystem.log.count, expected.count) {
                XCTAssertEqual(TestSystem.log[i], expected[i], "item \(i) failed")
            }
        } catch {
            XCTFail("unexpected error")
        }
    }


    func test_init_help() {
        XCTAssert(Heroku.Init.help.count > 0)
    }

}
