import XCTest
import JSON
import Vapor
import Foundation
import HTTP
import Redis
@testable import Cloud

let testNamePrefix = "test-"

class ApplicationApiTests: XCTestCase {
    func testRedeploy() throws {
        let token = try! adminApi.login(email: "test-1490982505.99255@gmail.com", pass: "real-secure")

        let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
            + "test-delete-me-123213"
            + "/hosting/environments/"
            + "master"
        let request = try! Request(method: .patch, uri: endpoint)
        request.access = token

        var json = JSON([:])
        try json.set("code", "incremental")
        request.json = json

        let response = try! client.respond(to: request)
        let id = try! response.json!["deployments.0.id"]!.string!
        try Redis.subscribeDeployLog(id: id) { update in
            print("Got update: \(update)")
        }
        print("response: \(response)")
        print("")
    }

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

        let environment = try applicationApi.hosting.environments.create(
            for: application,
            name: "staging",
            branch: "master",
            with: token
        )

        let allEnvs = try applicationApi.hosting.environments.all(for: application, with: token)
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
