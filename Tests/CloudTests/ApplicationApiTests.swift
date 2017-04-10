import XCTest
import JSON
import Vapor
import Foundation
import HTTP
import Redis
import Console
import Shared
@testable import Cloud

let testNamePrefix = "test-"

class GitUrlTests: XCTestCase {
    let git = GitInfo(Terminal(arguments: []))

    func testValidateGitUrl() throws {
        XCTAssertTrue(git.isSSHUrl("git@github.com:vapor/vapor.git"))
        XCTAssertFalse(git.isSSHUrl("https://github.com/vapor/vapor"))
        XCTAssertNil(git.resolvedUrl("git@github"))
    }

    func testConvertGitUrl() throws {

        let one = git.convertToSSHUrl("https://www.github.com/vapor/api-template/")
        let two = git.convertToSSHUrl("https://github.com/vapor/api-template.git")
        let three = git.convertToSSHUrl("https://www.github.com/vapor/api-template/")
        let four = git.convertToSSHUrl("https://www.github.com/vapor/api-template/")

        let expectation = "git@github.com:vapor/api-template.git"
        [one, two, three, four].forEach { XCTAssertEqual($0, expectation) }
    }
}

import URI

class ApplicationApiTests {
    let user: User
    let token: Token
    let org: Organization
    let proj: Project

    init(token: Token, user: User, org: Organization, proj: Project) {
        self.token = token
        self.user = user
        self.org = org
        self.proj = proj
    }

    func test() throws {
        try testAll(expectCount: 0, contains: nil)
        let app = try testCreate()
        try testAll(expectCount: 1, contains: app)
        try testProjectGet(expectCount: 1, contains: app)

        let hostingTests = HostingTests(token: token, app: app)
        let hosting = try hostingTests.test()
        try testAppByGit(git: hosting.gitUrl, matches: app)

        let envTests = EnvironmentApiTests(token: token, app: app, hosting: hosting)
        let env = try envTests.test()

        let deployTests = DeployApiTests(app: app, env: env, token: token)
        try deployTests.test()
    }

    func testCreate() throws -> Application {
        let uniqueRepo = UUID().uuidString
            .makeBytes()
            .filter { $0 != .hyphen }
            .prefix(20) // length limit
            .makeString()
        let app = try applicationApi.create(
            for: proj,
            repo: uniqueRepo,
            name: "My App",
            with: token
        )

        XCTAssertEqual(app.repo, uniqueRepo, "repo on app create doesn't match")
        XCTAssertEqual(app.name, "My App", "name on app create doesn't match")
        XCTAssertEqual(app.projectId, proj.id, "project id on app create doesn't match")

        return app
    }

    func testAll(expectCount: Int, contains: Application?) throws {
        let found = try applicationApi.all(with: token)
        XCTAssertEqual(found.count, expectCount)
        if let contains = contains {
            XCTAssert(found.contains(contains), "\(found) doesn't contain \(contains)")
        }
    }

    func testProjectGet(expectCount: Int, contains: Application) throws {
        let found = try applicationApi.get(for: proj, with: token)
        XCTAssertEqual(found.count, expectCount)
        found.forEach { app in
            XCTAssertEqual(app.projectId, proj.id)
        }
        XCTAssert(found.contains(contains), "\(found) doesn't contain \(contains)")
    }

    func testAppByGit(git: String, matches expectation: Application) throws {
        let apps = try applicationApi.get(forGit: git, with: token)
        XCTAssertEqual(apps.count, 1)
        XCTAssert(apps.contains(expectation), "apps \(apps) doesn't contain \(expectation)")
    }
}

final class HostingTests {
    let token: Token
    let app: Application
    let gitUrl = "git@github.com:vapor/light-template.git"

    init(token: Token, app: Application) {
        self.token = token
        self.app = app
    }

    func test() throws -> Hosting {
        try testGet(expect: nil)
        let new = try testCreate()
        try testGet(expect: new)
        try testUpdate(input: new)
        return new
    }

    func testCreate() throws -> Hosting {
        let hosting = try applicationApi.hosting.create(
            forRepo: app.repo,
            git: gitUrl,
            with: token
        )

        XCTAssertEqual(hosting.application.id, app.id)
        XCTAssertEqual(hosting.gitUrl, gitUrl)
        return hosting
    }

    func testGet(expect: Hosting?) throws {
        let found = try? applicationApi.hosting.get(forRepo: app.repo, with: token)
        XCTAssertEqual(found, expect)
    }

    func testUpdate(input: Hosting) throws {
        let subGit = "git@github.com:vapor/todo-example.git"
        let new = try applicationApi.hosting.update(
            for: app,
            git: subGit,
            with: token
        )

        XCTAssertEqual(new.gitUrl, subGit)
        XCTAssertEqual(new.application.id, app.id)
        XCTAssertNotEqual(new, input)

        // Revert
        let back = try applicationApi.hosting.update(
            for: app,
            git: input.gitUrl,
            with: token
        )
        XCTAssertEqual(back, input)
    }
}

final class EnvironmentApiTests {
    let token: Token
    let app: Application
    let hosting: Hosting

    init(token: Token, app: Application, hosting: Hosting) {
        self.token = token
        self.app = app
        self.hosting = hosting
    }

    func test() throws -> Cloud.Environment {
        try testAll(expectCount: 0, contains: nil)
        let env = try testCreate()
        try testAll(expectCount: 1, contains: env)
        try testUpdate(with: env)
        return env
    }

    func testAll(expectCount: Int, contains: Cloud.Environment?) throws {
        let found = try applicationApi.hosting.environments.all(for: app, with: token)
        XCTAssertEqual(found.count, expectCount)
        if let contains = contains {
            XCTAssert(found.contains(contains))
        }
    }

    func testCreate() throws -> Cloud.Environment {
        let env = try applicationApi.hosting.environments.create(
            forRepo: app.repo,
            name: "new-env",
            branch: "master",
            with: token
        )

        XCTAssertEqual(env.defaultBranch, "master")
        XCTAssertEqual(env.name, "new-env")
        XCTAssertEqual(env.replicas, 0)
        XCTAssertEqual(env.hosting.id, hosting.id)
        XCTAssertEqual(env.running, false)

        return env
    }

    func testUpdate(with env: Cloud.Environment) throws {
        XCTAssertEqual(env.replicas, 0)

        let patched = try applicationApi.hosting.environments.setReplicas(
            count: 1,
            forRepo: app.repo,
            env: env,
            with: token
        )
        
        XCTAssertEqual(patched.name, env.name)
        XCTAssertEqual(patched.hosting.id, env.hosting.id)
        XCTAssertEqual(patched.defaultBranch, env.defaultBranch)
        XCTAssertEqual(patched.replicas, 1)
    }
}

final class DeployApiTests {
    let app: Application
    let env: Cloud.Environment
    let token: Token
    init(app: Application, env: Cloud.Environment, token: Token) {
        self.app = app
        self.env = env
        self.token = token
    }

    func test() throws {
        let _ = try testPush()
        let _ = try testScale()
    }

    func testPush() throws -> Deploy {
        return try applicationApi.deploy.push(
            repo: app.repo,
            envName: env.name,
            gitBranch: nil,
            replicas: nil,
            code: .update,
            with: token
        )
    }

    func testScale() throws {
        try applicationApi.deploy.scale(
            repo: app.repo,
            envName: env.name,
            replicas: 2,
            with: token
        )
    }
}
