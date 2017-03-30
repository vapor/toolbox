import XCTest
import JSON
import Vapor
import Foundation
import HTTP
@testable import Cloud

class UserApiTests: XCTestCase {
    func testCloud() throws {
        let (email, pass, token) = try! testUserApi()
        let org = try! testOrganizationApi(email: email, pass: pass, token: token)
        try! testProjects(organization: org, token: token)
        try! testOrganizationPermissions(token: token)
    }

    func testUserApi() throws -> (email: String, pass: String, access: Token) {
        // TODO: Breakout create/login/get to convenience
        let email = "fake-\(Date().timeIntervalSince1970)@gmail.com"
        let pass = "real-secure"
        try createUser(email: email, pass: pass)
        let token = try adminApi.login(email: email, pass: pass)
        let user = try adminApi.user.get(with: token)
        XCTAssertEqual(user.email, email)

        let newToken = try adminApi.access.refresh(with: token)
        XCTAssertNotEqual(token, newToken)

        return (email, pass, newToken)
    }

    func createUser(email: String, pass: String) throws {
        let firstName = "Hello"
        let lastName = "World"
        let response = try adminApi.create(
            email: email,
            pass: pass,
            firstName: firstName,
            lastName: lastName,
            organizationName: "Broken Endpoint, Inc.",
            image: nil
        )

        XCTAssertNotNil(response.json)
        let json = response.json ?? JSON()
        let _ = try json.get("id") as UUID
        XCTAssertEqual(json["email"]?.string, email)
        XCTAssertEqual(json["name.first"]?.string, firstName)
        XCTAssertEqual(json["name.last"]?.string, lastName)
    }

    func testOrganizationApi(email: String, pass: String, token: Token) throws -> Organization {
        let org = "Real Business, Inc."
        let new = try adminApi.organizations.create(name: org, with: token)
        XCTAssertEqual(new.name, org)

        let list = try adminApi.organizations.all(with: token)
        XCTAssert(list.contains(new))

        let one = try adminApi.organizations.get(id: new.id, with: token)
        XCTAssertEqual(one, new)

        return one
    }

    func testProjects(organization: Organization, token: Token) throws {
        let name = "Fun Awesome Proj!"
        let project = try adminApi.projects.create(
            name: name,
            color: nil,
            organizationId: organization.id.uuidString,
            with: token
        )

        let testPrefix = name.bytes.prefix(2).makeString()
        let all = try adminApi.projects.get(query: testPrefix, with: token)
        XCTAssert(all.contains(project))

        let single = try adminApi.projects.get(id: project.id, with: token)
        XCTAssertEqual(project, single)

        try testColors(token: token)

        let updated = try adminApi.projects.update(single, name: "I'm different", color: nil, with: token)
        XCTAssertEqual(single.id, updated.id)
        XCTAssertEqual(single.color, updated.color)
        XCTAssertEqual(single.organizationId, updated.organizationId)
        XCTAssertNotEqual(single.name, updated.name)

        let permissions = try adminApi.projects.permissions.get(for: updated, with: token)
        XCTAssert(!permissions.isEmpty)

        let allPermissions = try adminApi.projects.permissions.all(with: token)
        permissions.forEach { permission in
            XCTAssert(allPermissions.contains(permission))
        }

        // TODO: Make comprehensive code to create and login
        let email = "fake-\(Date().timeIntervalSince1970)@gmail.com"
        let pass = "real-secure"
        try createUser(email: email, pass: pass)
        let newToken = try adminApi.login(email: email, pass: pass)
        let newUser = try adminApi.user.get(with: newToken)

        let currentPermissions = try adminApi.projects.permissions.get(for: single, with: newToken)
        XCTAssert(currentPermissions.isEmpty)

        // TODO: why not id?
        let perms = allPermissions.map { $0.key }
        let updatedPermissions = try adminApi.projects.permissions.set(
            perms,
            for: newUser,
            in: updated,
            with: token
        )
        XCTAssertEqual(updatedPermissions, allPermissions)
    }

    func testOrganizationPermissions(token: Token) throws {
        let organizations = try adminApi.organizations.all(with: token)
        XCTAssert(!organizations.isEmpty)
        let allPermissions = try adminApi.organizations.permissions.all(with: token)

        let org = organizations[0]

        let email = "fake-\(Date())@gmail.com"
        let pass = "real-secure"
        let newToken = try adminApi.createAndLogin(
            email: email,
            pass: pass,
            firstName: "Foo",
            lastName: "Bar",
            organizationName: "Real Organization",
            image: nil
        )
        let newUser = try adminApi.user.get(with: newToken)

        let prePermissions = try adminApi.organizations.permissions.get(
            for: org,
            with: newToken
        )
        XCTAssert(prePermissions.isEmpty)
        let postPermissions = try adminApi.organizations.permissions.set(
            // should this be ids?
            allPermissions.map { $0.key },
            for: newUser,
            in: org,
            with: token
        )
        XCTAssertEqual(postPermissions, allPermissions)
    }

    func testColors(token: Token) throws {
        let colors = try adminApi.projects.colors(with: token)
        XCTAssert(!colors.isEmpty)
    }
}
