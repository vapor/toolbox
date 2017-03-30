import XCTest
import JSON
import Vapor
import Foundation
import HTTP
@testable import Cloud

// admin-api-staging.vapor.cloud
// admin-api.vapor.cloud
// api.vapor.cloud/admin
// api-staging.vapor.cloud/admin

extension String: Error {}

struct Token {
    let access: String
    let refresh: String
}

extension Token: Equatable {}
func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.access == rhs.access
        && lhs.refresh == rhs.refresh
}

final class User: NodeInitializable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let imageUrl: String?

    init(node: Node) throws {
        id = try node.get("id")
        firstName = try node.get("name.first")
        lastName = try node.get("name.last")
        email = try node.get("email")
        imageUrl = try node.get("imageUrl")
    }
}

final class Organization: NodeInitializable {
    let id: UUID
    let name: String
    init(node: Node) throws {
        id = try node.get("id")
        name = try node.get("name")
    }
}

extension Organization: Equatable {}
func == (lhs: Organization, rhs: Organization) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
}

final class AdminApi {
    fileprivate static let base = "https://admin-api-staging.vapor.cloud/admin"
    fileprivate static let usersEndpoint = "\(base)/users"
    fileprivate static let loginEndpoint = "\(base)/login"
    fileprivate static let meEndpoint = "\(base)/me"
    fileprivate static let refreshEndpoint = "\(base)/refresh"
    fileprivate static let organizationsEndpoint = "\(base)/organizations"
    fileprivate static let projectsEndpoint = "\(base)/projects"

    // client
    fileprivate static let client = EngineClient.self

    let user = UserApi()
    let access = AccessApi()
    let organizations = OrganizationApi()
    let projects = ProjectsApi()
}

extension AdminApi {
    final class UserApi {
        func createAndLogin(
            email: String,
            pass: String,
            firstName: String,
            lastName: String,
            organization: String,
            image: String?
        ) throws -> (user: User, token: Token) {
            try create(
                email: email,
                pass: pass,
                firstName: firstName,
                lastName: lastName,
                organization: organization,
                image: image
            )
            let token = try adminApi.user.login(email: email, pass: pass)
            let user = try adminApi.user.get(with: token)
            return (user, token)
        }

        @discardableResult
        func create(email: String, pass: String, firstName: String, lastName: String, organization: String, image: String?) throws -> Response {
            var json = JSON([:])
            try json.set("email", email)
            try json.set("password", pass)
            try json.set("name.first", firstName)
            try json.set("name.last", lastName)
            try json.set("organization.name", organization)
            if let image = image {
                try json.set("image", image)
            }

            let request = try Request(method: .post, uri: usersEndpoint)
            request.json = json

            return try client.respond(to: request)
        }

        func login(email: String, pass: String) throws -> Token {
            var json = JSON([:])
            try json.set("email", email)
            try json.set("password", pass)

            let request = try Request(method: .post, uri: loginEndpoint)
            request.json = json
            let response = try client.respond(to: request)
            guard
                let access = response.json?["accessToken"]?.string,
                let refresh = response.json?["refreshToken"]?.string
                else { throw "Bad response to login: \(response)" }

            return Token(access: access, refresh: refresh)
        }

        func get(with token: Token) throws -> User {
            let request = try Request(method: .get, uri: meEndpoint)
            request.access = token

            let response = try client.respond(to: request)
            guard let json = response.json else {
                throw "Bad response to authed user: \(response)"
            }

            return try User(node: json)
        }
    }
}

extension AdminApi {
    final class AccessApi {
        func refresh(with token: Token) throws -> Token {
            let request = try Request(method: .get, uri: refreshEndpoint)
            request.refresh = token
            let response = try client.respond(to: request)
            guard let refresh = response.json?["accessToken"]?.string else {
                throw "Bad response to refresh request: \(response)"
            }
            return Token(access: token.access, refresh: refresh)
        }
    }
}

extension AdminApi {
    final class OrganizationApi {
        final class PermissionsApi {
            func get(organization: String, with token: Token) throws -> [Permission] {
                let endpoint = organizationsEndpoint.finished(with: "/") + organization + "/permissions"
                let request = try Request(method: .get, uri: endpoint)
                request.access = token

                let response = try client.respond(to: request)
                guard let json = response.json?.array else {
                    throw "Bad response for project permissions: \(response)"
                }
                return try [Permission](node: json)
            }

            func all(with token: Token) throws -> [Permission] {
                let endpoint = organizationsEndpoint.finished(with: "/") + "permissions"
                let request = try Request(method: .get, uri: endpoint)
                request.access = token

                let response = try client.respond(to: request)
                guard let json = response.json?.array else {
                    throw "Bad response for project permissions: \(response)"
                }
                return try [Permission](node: json)
            }

            func update(_ permissions: [String], forUser user: String, inOrganization organization: String, with token: Token) throws -> [Permission] {
                let endpoint = organizationsEndpoint.finished(with: "/") + organization + "/permissions"
                let request = try Request(method: .put, uri: endpoint)
                request.access = token

                var json = JSON([:])
                try json.set("userId", user)
                // TODO: Why are we using permission keys here instead of id
                // kind of feels like duplicate ids
                try json.set("permissions", permissions)
                request.json = json

                let response = try client.respond(to: request)
                guard let permissions = response.json?.array else {
                    throw "Bad response to update permissions: \(response)"
                }

                return try [Permission](node: permissions)
            }
        }
        
        let permissions = PermissionsApi()

        func create(name: String, with token: Token) throws -> Organization {
            let request = try Request(method: .post, uri: organizationsEndpoint)
            request.access = token
            request.json = try JSON(node: ["name": name])
            let response = try client.respond(to: request)
            guard let json = response.json else { throw "Bad response organization create \(response)" }
            return try Organization(node: json)
        }

        func all(with token: Token) throws -> [Organization] {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.access = token
            let response = try client.respond(to: request)
            // TODO: Should handle pagination
            guard let json = response.json?["data"]?.array else { throw "Bad response organization create \(response)" }
            return try [Organization](node: json)
        }

        // TODO: Remove
        func get(with token: Token) throws -> [Organization] {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.access = token
            let response = try client.respond(to: request)
            // TODO: Should handle pagination
            guard let json = response.json?["data"]?.array else { throw "Bad response organization create \(response)" }
            return try [Organization](node: json)
        }

        func get(id: UUID, with token: Token) throws -> Organization {
            return try get(id: id.uuidString, with: token)
        }

        func get(id: String, with token: Token) throws -> Organization {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.access = token
            request.json = try JSON(node: ["id": id])
            let response = try client.respond(to: request)
            // TODO: Discuss w/ Tanner, should this really be returning an array?
            guard let json = response.json?["data"]?.array?.first else { throw "Bad response organization create \(response)" }
            return try Organization(node: json)
        }
    }
}

struct Project: NodeInitializable {
    let id: UUID
    let name: String
    let color: String
    let organizationId: UUID

    init(node: Node) throws {
        id = try node.get("id")
        name = try node.get("name")
        color = try node.get("color")
        // some endpoints don't return full object, 
        // this is easier for now
        organizationId = try node.get("organization.id")
    }
}

extension Project: Equatable {}
func == (lhs: Project, rhs: Project) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.color == rhs.color
        && lhs.organizationId == rhs.organizationId
}

struct Permission: NodeInitializable {
    let id: UUID
    let key: String

    init(node: Node) throws {
        id = try node.get("id")
        key = try node.get("key")
    }
}

extension Permission: Equatable {}
func == (lhs: Permission, rhs: Permission) -> Bool {
    return lhs.id == rhs.id
        && lhs.key == rhs.key
}

extension AdminApi {
    final class ProjectsApi {
        final class PermissionsApi {
            func get(project: String, with token: Token) throws -> [Permission] {
                let endpoint = projectsEndpoint.finished(with: "/") + project + "/permissions"
                let request = try Request(method: .get, uri: endpoint)
                request.access = token

                let response = try client.respond(to: request)
                guard let json = response.json?.array else {
                    throw "Bad response for project permissions: \(response)"
                }
                return try [Permission](node: json)
            }

            func all(with token: Token) throws -> [Permission] {
                let endpoint = projectsEndpoint.finished(with: "/") + "permissions"
                let request = try Request(method: .get, uri: endpoint)
                request.access = token

                let response = try client.respond(to: request)
                guard let json = response.json?.array else {
                    throw "Bad response for project permissions: \(response)"
                }
                return try [Permission](node: json)
            }

            func update(_ permissions: [String], forUser user: String, inProject project: String, with token: Token) throws -> [Permission] {
                let endpoint = projectsEndpoint.finished(with: "/") + project + "/permissions"
                let request = try Request(method: .put, uri: endpoint)
                request.access = token

                var json = JSON([:])
                try json.set("userId", user)
                // TODO: Why are we using permission keys here instead of id
                // kind of feels like duplicate ids
                try json.set("permissions", permissions)
                request.json = json

                let response = try client.respond(to: request)
                guard let permissions = response.json?.array else {
                    throw "Bad response to update permissions: \(response)"
                }
                
                return try [Permission](node: permissions)
            }
        }

        let permissions = PermissionsApi()

        func create(name: String, color: String?, organizationId: String, with token: Token) throws -> Project {
            let projectsUri = organizationsEndpoint.finished(with: "/") + organizationId + "/projects"
            let request = try Request(method: .post, uri: projectsUri)
            request.access = token

            var json = JSON()
            try json.set("name", name)
            if let color = color {
                try json.set("color", color)
            }
            request.json = json

            let response = try client.respond(to: request)
            guard let project = response.json else {
                throw "Bad response create project: \(response)"
            }

            return try Project(node: project)
        }

        func get(query: String, with token: Token) throws -> [Project] {
            let endpoint = projectsEndpoint + "?name=\(query)"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            guard let json = response.json?["data"]?.array else {
                throw "Bad response get projects: \(response)"
            }

            return try [Project](node: json)
        }

        func get(id: UUID, with token: Token) throws -> Project {
            return try get(id: id.uuidString, with: token)
        }

        func get(id: String, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + id
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            guard let json = response.json else {
                throw "Bad request single project: \(response)"
            }

            return try Project(node: json)
        }

        func update(_ project: Project, name: String?, color: String?, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + project.id.uuidString
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name ?? project.name)
            try json.set("color", color ?? project.color)
            request.json = json

            let response = try client.respond(to: request)
            guard let project = response.json else {
                throw "Bad response to project update: \(response)"
            }

            return try Project(node: project)
        }

        func colors(with token: Token) throws -> [Color] {
            let endpoint = projectsEndpoint.finished(with: "/") + "colors"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            let colors: [Color]? = response.json?
                .object?
                .map { name, hex in
                    let hex = hex.string ?? ""
                    return Color(name: name, hex: hex)
                }
            guard let unwrapped = colors else {
                throw "Bad response project colors: \(response)"
            }

            return unwrapped
        }
    }
}

extension Request {
    var access: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.access)"
        }
    }
    var refresh: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.refresh)"
        }
    }
}

struct Color {
    let name: String
    let hex: String
}

let adminApi = AdminApi()

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
        let token = try adminApi.user.login(email: email, pass: pass)
        let user = try adminApi.user.get(with: token)
        XCTAssertEqual(user.email, email)

        let newToken = try adminApi.access.refresh(with: token)
        XCTAssertNotEqual(token, newToken)

        return (email, pass, newToken)
    }

    func createUser(email: String, pass: String) throws {
        let firstName = "Hello"
        let lastName = "World"
        let response = try adminApi.user.create(
            email: email,
            pass: pass,
            firstName: firstName,
            lastName: lastName,
            organization: "Broken Endpoint, Inc.",
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

        let list = try adminApi.organizations.get(with: token)
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

        let permissions = try adminApi.projects.permissions.get(project: updated.id.uuidString, with: token)
        XCTAssert(!permissions.isEmpty)

        let allPermissions = try adminApi.projects.permissions.all(with: token)
        permissions.forEach { permission in
            XCTAssert(allPermissions.contains(permission))
        }

        // TODO: Make comprehensive code to create and login
        let email = "fake-\(Date().timeIntervalSince1970)@gmail.com"
        let pass = "real-secure"
        try createUser(email: email, pass: pass)
        let newToken = try adminApi.user.login(email: email, pass: pass)
        let newUser = try adminApi.user.get(with: newToken)

        let currentPermissions = try adminApi.projects.permissions.get(project: single.id.uuidString, with: newToken)
        XCTAssert(currentPermissions.isEmpty)

        // TODO: why not id?
        let perms = allPermissions.map { $0.key }
        let updatedPermissions = try adminApi.projects.permissions.update(
            perms,
            forUser: newUser.id.uuidString,
            inProject: updated.id.uuidString,
            with: token
        )
        XCTAssertEqual(updatedPermissions, allPermissions)
    }

    func testOrganizationPermissions(token: Token) throws {
        let organizations = try adminApi.organizations.get(with: token)
        XCTAssert(!organizations.isEmpty)
        let allPermissions = try adminApi.organizations.permissions.all(with: token)

        let org = organizations[0]

        let email = "fake-\(Date())@gmail.com"
        let pass = "real-secure"
        let newUser = try adminApi.user.createAndLogin(
            email: email,
            pass: pass,
            firstName: "Foo",
            lastName: "Bar",
            organization: "Real Organization",
            image: nil
        )

        let prePermissions = try adminApi.organizations.permissions.get(
            organization: org.id.uuidString,
            with: newUser.token
        )
        XCTAssert(prePermissions.isEmpty)
        let postPermissions = try adminApi.organizations.permissions.update(
            // should this be ids?
            allPermissions.map { $0.key },
            forUser: newUser.user.id.uuidString,
            inOrganization: org.id.uuidString,
            with: token
        )
        XCTAssertEqual(postPermissions, allPermissions)
    }

    func testColors(token: Token) throws {
        let colors = try adminApi.projects.colors(with: token)
        XCTAssert(!colors.isEmpty)
    }
}
