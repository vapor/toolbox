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

        func login(email: String, pass: String) throws -> (accessToken: String, refreshToken: String) {
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

            return (access, refresh)
        }

        func get(accessToken: String) throws -> User {
            let request = try Request(method: .get, uri: meEndpoint)
            request.token = accessToken

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
        func refresh(refreshToken: String) throws -> String {
            let request = try Request(method: .get, uri: refreshEndpoint)
            request.token = refreshToken
            let response = try client.respond(to: request)
            guard let token = response.json?["accessToken"]?.string else {
                throw "Bad response to refresh request: \(response)"
            }
            return token
        }
    }
}

extension AdminApi {
    final class OrganizationApi {
        func create(name: String, accessToken: String) throws -> Organization {
            let request = try Request(method: .post, uri: organizationsEndpoint)
            request.token = accessToken
            request.json = try JSON(node: ["name": name])
            let response = try client.respond(to: request)
            guard let json = response.json else { throw "Bad response organization create \(response)" }
            return try Organization(node: json)
        }

        func get(access: String) throws -> [Organization] {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.token = access
            let response = try client.respond(to: request)
            // TODO: Should handle pagination
            guard let json = response.json?["data"]?.array else { throw "Bad response organization create \(response)" }
            return try [Organization](node: json)
        }

        func get(id: UUID, access: String) throws -> Organization {
            return try get(id: id.uuidString, access: access)
        }

        func get(id: String, access: String) throws -> Organization {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.token = access
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

extension AdminApi {
    final class ProjectsApi {
        func create(name: String, color: String?, organizationId: String, access: String) throws -> Project {
            let projectsUri = organizationsEndpoint.finished(with: "/") + organizationId + "/projects"
            let request = try Request(method: .post, uri: projectsUri)
            request.token = access

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

        func get(query: String, access: String) throws -> [Project] {
            let endpoint = projectsEndpoint + "?name=\(query)"
            let request = try Request(method: .get, uri: endpoint)
            request.token = access

            let response = try client.respond(to: request)
            guard let json = response.json?["data"]?.array else {
                throw "Bad response get projects: \(response)"
            }

            return try [Project](node: json)
        }

        func get(id: UUID, access: String) throws -> Project {
            return try get(id: id.uuidString, access: access)
        }

        func get(id: String, access: String) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + id
            let request = try Request(method: .get, uri: endpoint)
            request.token = access

            let response = try client.respond(to: request)
            guard let json = response.json else {
                throw "Bad request single project: \(response)"
            }

            return try Project(node: json)
        }

        func update(_ project: Project, name: String?, color: String?, access: String) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + project.id.uuidString
            let request = try Request(method: .patch, uri: endpoint)
            request.token = access

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

        func colors(access: String) throws -> [Color] {
            let endpoint = projectsEndpoint.finished(with: "/") + "colors"
            let request = try Request(method: .get, uri: endpoint)
            request.token = access

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
    var token: String {
        get {
            fatalError()
        }
        set {
            headers["Authorization"] = "Bearer \(newValue)"
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
        let (email, pass, access) = try testUserApi()
        let org = try testOrganizationApi(email: email, pass: pass, access: access)
        try testProjects(organization: org, access: access)
    }

    func testUserApi() throws -> (email: String, pass: String, access: String) {
        let email = "fake-\(Date().timeIntervalSince1970)@gmail.com"
        let pass = "real-secure"
        try createUser(email: email, pass: pass)
        let (access, refresh) = try adminApi.user.login(email: email, pass: pass)
        let user = try adminApi.user.get(accessToken: access)
        XCTAssertEqual(user.email, email)

        let newToken = try adminApi.access.refresh(refreshToken: refresh)
        XCTAssertNotEqual(access, newToken)

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

    func testOrganizationApi(email: String, pass: String, access: String) throws -> Organization {
        let org = "Real Business, Inc."
        let new = try adminApi.organizations.create(name: org, accessToken: access)
        XCTAssertEqual(new.name, org)

        let list = try adminApi.organizations.get(access: access)
        XCTAssert(list.contains(new))

        let one = try adminApi.organizations.get(id: new.id, access: access)
        XCTAssertEqual(one, new)

        return one
    }

    func testProjects(organization: Organization, access: String) throws {
        let name = "Fun Awesome Proj!"
        let project = try adminApi.projects.create(
            name: name,
            color: nil,
            organizationId: organization.id.uuidString,
            access: access
        )

        let testPrefix = name.bytes.prefix(2).makeString()
        let all = try adminApi.projects.get(query: testPrefix, access: access)
        XCTAssert(all.contains(project))

        let single = try adminApi.projects.get(id: project.id, access: access)
        XCTAssertEqual(project, single)

        try testColors(access: access)

        let updated = try adminApi.projects.update(single, name: "I'm different", color: nil, access: access)
        XCTAssertEqual(single.id, updated.id)
        XCTAssertEqual(single.color, updated.color)
        XCTAssertEqual(single.organizationId, updated.organizationId)
        XCTAssertNotEqual(single.name, updated.name)
    }

    func testColors(access: String) throws {
        let colors = try adminApi.projects.colors(access: access)
        XCTAssert(!colors.isEmpty)
    }
}
