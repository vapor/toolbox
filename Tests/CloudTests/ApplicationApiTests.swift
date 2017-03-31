import XCTest
import JSON
import Vapor
import Foundation
import HTTP
@testable import Cloud

let testNamePrefix = "aAa - "
class ApplicationApiTests: XCTestCase {
    func testCreateApplication() throws {
        let email = newEmail()
        let token = try adminApi.createAndLogin(
            email: email,
            pass: pass,
            firstName: "Testerton",
            lastName: "Reelston",
            organizationName: "Real Business, Inc.",
            image: nil
        )

        guard let org = try adminApi.organizations.all(with: token).first else {
            XCTFail("Failed to get organization for test user")
            return
        }

        let project = try adminApi.projects.create(
            name: "Test-Project",
            color: nil,
            in: org,
            with: token
        )

        let name = testNamePrefix + Date().timeIntervalSince1970.description
        let application = try! applicationApi.create(
            for: project,
            repo: "test-app-\(Int(Date().timeIntervalSince1970))",
            git: "git@github.com:vapor/api-template.git",
            name: name,
            with: token
        )
        print(application)
        print("")
    }
}
