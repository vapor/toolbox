import HTTP
import Vapor

public let adminApi = AdminApi()

public var client = CloudClient<EngineClient>.self

import Transport
import TLS
import Sockets
extension FoundationClient: ClientProtocol {
    public convenience init(
        hostname: String,
        port: Port,
        _ securityLayer: SecurityLayer
        ) throws {
        let scheme: String
        if case .none = securityLayer {
            scheme = "http"
        } else {
            scheme = "https"
        }
        self.init(scheme: scheme, hostname: hostname, port: port)
    }
}

public final class AdminApi {
    internal static let base = "https://api.vapor.cloud/admin"
    internal static let usersEndpoint = "\(base)/users"
    internal static let loginEndpoint = "\(base)/login"
    internal static let meEndpoint = "\(base)/me"
    internal static let refreshEndpoint = "\(base)/refresh"
    internal static let organizationsEndpoint = "\(base)/organizations"
    internal static let projectsEndpoint = "\(base)/projects"

    // client

    public let user = UserApi()
    public let access = AccessApi()
    public let organizations = OrganizationApi()
    public let projects = ProjectsApi()
}

extension AdminApi {
    public func createAndLogin(
        email: String,
        pass: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        image: String?
        ) throws -> Token {
        try create(
            email: email,
            pass: pass,
            firstName: firstName,
            lastName: lastName,
            organizationName: organizationName,
            image: image
        )

        return try login(email: email, pass: pass)
    }

    @discardableResult
    public func create(
        email: String,
        pass: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        image: String?
    ) throws -> Response {
        var json = JSON([:])
        try json.set("email", email)
        try json.set("password", pass)
        try json.set("name.first", firstName)
        try json.set("name.last", lastName)
        try json.set("organization.name", organizationName)
        try json.set("image", image)

        let request = try Request(method: .post, uri: AdminApi.usersEndpoint)
        request.json = json

        return try client.respond(to: request)
    }

    public func login(email: String, pass: String) throws -> Token {
        var json = JSON([:])
        try json.set("email", email)
        try json.set("password", pass)

        let request = try Request(method: .post, uri: AdminApi.loginEndpoint)
        request.json = json
        let response = try client.respond(to: request)
        guard
            let access = response.json?["accessToken"]?.string,
            let refresh = response.json?["refreshToken"]?.string
            else { throw "Bad response to login: \(response)" }

        return Token(access: access, refresh: refresh)
    }
}
