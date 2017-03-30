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

let adminBase = "https://admin-api-staging.vapor.cloud/admin"
final class UserApi {
    private let usersEndpoint = "\(adminBase)/users"
    private let loginEndpoint = "\(adminBase)/login"
    private let meEndpoint = "\(adminBase)/me"
    private let refreshEndpoint = "\(adminBase)/refresh"

    let client = EngineClient.self

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

    func getUser(accessToken: String) throws -> JSON {
        let request = try Request(method: .get, uri: meEndpoint)
        request.headers["Authorization"] = "Bearer \(accessToken)"

        let response = try client.respond(to: request)
        print(response)
        print("")
        guard let json = response.json else {
            throw "Bad response to authed user: \(response)"
        }

        return json
    }

    func refreshAccess(refreshToken: String) throws -> String {
        let request = try Request(method: .get, uri: refreshEndpoint)
        request.headers["Authorization"] = "Bearer \(refreshToken)"
        let response = try client.respond(to: request)
        guard token = response.json?["accessToken"] else {
            throw "Bad response to refresh request: \(response)"
        }
        return token
    }
}

let userApi = UserApi()

class UserApiTests: XCTestCase {
    func testCloud() throws {
        let email = "fake-\(Date().timeIntervalSince1970)@gmail.com"
        let pass = "real-secure"
        try createUser(email: email, pass: pass)
        let (access, refresh) = try userApi.login(email: email, pass: pass)
        print(access)
        print(refresh)
        print("")

        let userJson = try userApi.getUser(accessToken: access)
        XCTAssertEqual(userJson["email"]?.string, email)

        let newToken = try userApi.refreshAccess(refreshToken: refresh)
        XCTAssertNotEqual(access, newToken)
    }

    func createUser(email: String, pass: String) throws {
        let firstName = "Hello"
        let lastName = "World"
        let response = try userApi.create(
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
}
