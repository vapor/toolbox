import XCTest
import JSON
import Vapor
import Foundation
import HTTP
@testable import Cloud

func newEmail() -> String {
    return "fake-\(Date().timeIntervalSince1970)@gmail.com"
}

let pass = "real-secure"

class ApiTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // TODO: Uncomment if staging is consistent
        AdminApi.base = "https://admin-api-staging.vapor.cloud/admin"
        ApplicationApi.base = "https://application-api-staging.vapor.cloud/application"
    }

    func testApis() throws {
        let adminApiTests = AdminApiTests()
        let (token, user, org, proj) = try! adminApiTests.test()

        let applicationApiTests = ApplicationApiTests(
            token: token,
            user: user,
            org: org,
            proj: proj
        )
        try! applicationApiTests.test()
    }
}

final class AdminApiTests {
    func test() throws -> (Token, User, Organization, Project) {
        let (user, token) = try testSignupLogin()
        try testUserApi(with: token, expectation: user)
        try testAccessApi(with: token)

        let orgTests = OrganizationApiTests(user: user, token: token)
        let org = try orgTests.test()
        let projTests = ProjectApiTests(user: user, org: org, token: token)
        let proj = try projTests.test()

        return (token, user, org, proj)
    }

    func testSignupLogin() throws -> (user: User, token: Token) {
        let email = newEmail()
        let (user, token) = try adminApi.createAndLogin(
            email: email,
            pass: pass,
            firstName: "Test",
            lastName: "User",
            organizationName: "My Cloud",
            image: nil
        )

        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.firstName, "Test")
        XCTAssertEqual(user.lastName, "User")
        XCTAssertNil(user.imageUrl)

        return (user, token)
    }

    func testUserApi(with token: Token, expectation: User) throws {
        let found = try adminApi.user.get(with: token)
        XCTAssertEqual(found, expectation)
    }

    func testAccessApi(with token: Token) throws {
        let initialAccess = token.access
        let initialRefresh = token.refresh
        try adminApi.access.refresh(token)
        // refresh tokens don't change
        XCTAssertEqual(initialRefresh, token.refresh)
        // access token should update
        XCTAssertNotEqual(initialAccess, token.access)
    }
}

final class OrganizationApiTests {
    let user: User
    let token: Token

    init(user: User, token: Token) {
        self.user = user
        self.token = token
    }

    func test() throws -> Organization {
        try testAll(expectCount: 1, contains: nil)
        let org = try testCreate()
        try testAll(expectCount: 2, contains: org)
        try testGetIndividual(base: org)
        try testPermissions(against: org)
        return org
    }

    func testCreate() throws -> Organization {
        let org = try adminApi.organizations.create(
            name: "New Org",
            with: token
        )

        XCTAssertEqual(org.name, "New Org")
        return org
    }

    func testAll(expectCount: Int, contains: Organization?) throws {
        let found = try adminApi.organizations.all(with: token)
        XCTAssertEqual(found.count, expectCount)
        if let contains = contains {
            XCTAssert(found.contains(contains))
        }
    }

    func testGetIndividual(base: Organization) throws {
        let found = try adminApi.organizations.get(
            id: base.id,
            with: token
        )
        XCTAssertEqual(found, base)
    }

    func testPermissions(against org: Organization) throws {
        let all = try adminApi
            .organizations
            .permissions
            .all(with: token)
        let owned = try adminApi
            .organizations
            .permissions
            .get(for: org, with: token)
        XCTAssertEqualUnordered(all, owned)

        let new = try adminApi.createAndLogin(
            email: newEmail(),
            pass: pass,
            firstName: "Tester",
            lastName: "McRealBoy",
            organizationName: "My Cloud",
            image: nil
        )
        let existing = try adminApi.organizations.permissions.get(for: org, with: new.token)
        XCTAssert(existing.isEmpty)

        let set = try adminApi.organizations.permissions.set(
            all,
            forUser: new.user.id,
            in: org,
            with: token
        )
        XCTAssertEqualUnordered(set, all)
        
        let updated = try adminApi.organizations.permissions.get(
            for: org,
            with: new.token
        )
        XCTAssertEqualUnordered(updated, all)
    }
}

final class ProjectApiTests {
    let user: User
    let org: Organization
    let token: Token

    init(user: User, org: Organization, token: Token) {
        self.user = user
        self.org = org
        self.token = token
    }

    func test() throws -> Project {
        try testAll(expectCount: 0, contains: nil)
        let new = try testCreate()
        try testGetIndividual(expectation: new)
        try testAll(expectCount: 1, contains: new)
        try testColorsEndpoint()
        try testUpdate(input: new)
        try testPermissions(against: new)
        return new
    }

    func testAll(expectCount: Int, contains: Project?) throws {
        let found = try adminApi.projects.all(for: org, with: token)
        XCTAssertEqual(found.count, expectCount)
        if let contains = contains {
            XCTAssert(found.contains(contains))
        }

        found.forEach { proj in
            XCTAssertEqual(proj.organizationId, org.id)
        }
    }

    func testCreate() throws -> Project {
        let new = try adminApi.projects.create(
            name: "My Proj",
            color: nil,
            in: org,
            with: token
        )

        XCTAssertEqual(new.organizationId, org.id)
        XCTAssertEqual(new.name, "My Proj")
        return new
    }

    func testGetIndividual(expectation: Project) throws {
        let one = try adminApi.projects.get(
            id: expectation.id,
            with: token
        )
        XCTAssertEqual(one, expectation)

        let search = try adminApi.projects.get(
            prefix: expectation.name.bytes.prefix(3).makeString(),
            with: token
        )
        XCTAssert(search.contains(one))
    }

    func testColorsEndpoint() throws {
        _ = try adminApi.projects.colors(with: token)
    }

    func testUpdate(input: Project) throws {
        let updated = try adminApi.projects.update(
            input,
            name: "New Name",
            color: nil,
            with: token
        )
        XCTAssertEqual(updated.id, input.id)
        XCTAssertEqual(updated.color, input.color)
        XCTAssertNotEqual(updated.name, input.name)
    }


    func testPermissions(against proj: Project) throws {
        let all = try adminApi
            .projects
            .permissions
            .all(with: token)
        let owned = try adminApi
            .projects
            .permissions
            .get(for: proj, with: token)
        XCTAssertEqualUnordered(all, owned)

        let new = try adminApi.createAndLogin(
            email: newEmail(),
            pass: pass,
            firstName: "Tester",
            lastName: "McRealBoy",
            organizationName: "My Cloud",
            image: nil
        )
        let existing = try adminApi.projects.permissions.get(for: proj, with: new.token)
        XCTAssert(existing.isEmpty)

        let set = try adminApi.projects.permissions.set(
            all,
            forUser: new.user.id,
            in: proj,
            with: token
        )
        XCTAssertEqualUnordered(set, all)

        let updated = try adminApi.projects.permissions.get(
            for: proj,
            with: new.token
        )
        XCTAssertEqualUnordered(updated, all)
    }
}

func XCTAssertEqualUnordered<T: Equatable>(_ lhs: [T], _ rhs: [T]) {
    func fail() { XCTFail("lhs: \(lhs) != \(rhs)") }
    if lhs.count != rhs.count {
        fail()
    }
    let trues = lhs.map(rhs.contains).filter { $0 }
    if trues.count != lhs.count {
        fail()
    }
}
