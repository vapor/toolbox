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

func validateGitUri(_ test: String) throws {

}
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

//    func testRedeploy() throws {
//        let token = try! adminApi.login(email: "test-1490982505.99255@gmail.com", pass: "real-secure")
//
//        let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
//            + "test-delete-me-123213"
//            + "/hosting/environments/"
//            + "master"
//        let request = try! Request(method: .patch, uri: endpoint)
//        request.access = token
//
//        var json = JSON([:])
//        try json.set("code", "incremental")
//        request.json = json
//
//        let response = try! client.respond(to: request)
//        let id = try! response.json!["deployments.0.id"]!.string!
//        try Redis.subscribeDeployLog(id: id) { update in
//            print("Got update: \(update)")
//        }
//        print("response: \(response)")
//        print("")
//    }

    func testInfoFromGitUrl() throws {
//        let token = try adminApi.login(email: "test-1490982505.99255@gmail.com", pass: "real-secure")
//        let hosts = try applicationApi.hosting.all(with: token)
//        print(hosts)
//        print("")
//        let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + "hosting"
//
//        let request = try Request(method: .get, uri: endpoint)
//        request.access = token
//
//        let response = try client.respond(to: request)
//        print(response)
//        print("")
    }

    func _testCreateApplication() throws {
//        let email = newEmail()
//        print(" email '\(email)'")
//        print("")
//        let token = try adminApi.createAndLogin(
//            email: email,
//            pass: pass,
//            firstName: "Testerton",
//            lastName: "Reelston",
//            organizationName: "Real Business, Inc.",
//            image: nil
//        )
        let token = try adminApi.login(email: "test-1490982505.99255@gmail.com", pass: "real-secure")
        guard let project = try adminApi.projects.all(with: token).first else {
            XCTFail("Failed to get project for test user")
            return
        }

//        let project = try! adminApi.projects.create(
//            name: "Test-Project",
//            color: nil,
//            in: org,
//            with: token
//        )

        let name = testNamePrefix + Int(Date().timeIntervalSince1970).description
        let repo = name
        let application = try applicationApi.create(
            for: project,
            repo: repo,
            name: name,
            with: token
        )
        XCTAssertEqual(application.name, name)
        XCTAssertEqual(application.repo, repo)
        XCTAssertEqual(application.projectId, project.id)

        let applications = try applicationApi.get(for: project, with: token)
        XCTAssertEqual(applications.first, application)

        let create = try applicationApi.hosting.create(
            for: application,
            git: "git@github.com:vapor/api-template.git",
            with: token
        )
        let fetch = try applicationApi.hosting.get(
            for: application,
            with: token
        )
        XCTAssertEqual(create, fetch)

        let update = try applicationApi.hosting.update(
            for: application,
            git: "git@github.com:vapor/light-template.git",
            with: token
        )
        XCTAssertNotEqual(update.gitUrl, fetch.gitUrl)

        let environment = try applicationApi.environments.create(
            for: application,
            name: "staging",
            branch: "master",
            with: token
        )

        let allEnvs = try applicationApi.environments.all(for: application, with: token)
        XCTAssert(allEnvs.map { $0.id } .contains(environment.id))
        try applicationApi.deploy.deploy(
            for: application,
            replicas: 1,
            env: environment,
            code: .incremental,
            with: token
        )
    }
}
