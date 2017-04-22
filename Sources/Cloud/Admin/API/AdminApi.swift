import HTTP
import Vapor

public let adminApi = AdminApi()

public var client = ClientFactory<CloudClient<EngineClient>>()

import Transport
extension FoundationClient: ClientProtocol {
    public convenience init(hostname: String, port: Port, _ securityLayer: SecurityLayer) throws {
        // TODO: Forcing https a tm
        self.init(scheme: "https", hostname: hostname, port: port)
    }
}
import Transport
import TLS
import Sockets

/// The admin api will be used for user based
/// endpoints, for example, login/out
/// access, and organizations
public final class AdminApi {
    internal static var base = "http://0.0.0.0:8100/admin"
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
    // TODO: Rename signup/login, and signupAndLogin
    @discardableResult
    public func create(
        email: String,
        pass: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        image: String?
    ) throws -> User {
        var json = JSON([:])
        try json.set("email", email)
        try json.set("password", pass)
        try json.set("name.first", firstName)
        try json.set("name.last", lastName)
        try json.set("organization.name", organizationName)
        try json.set("image", image)

        let request = try Request(method: .post, uri: AdminApi.usersEndpoint)
        request.json = json

        let response = try client.respond(to: request)
        return try User(node: response.json)
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

    public func createAndLogin(
        email: String,
        pass: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        image: String?
    ) throws -> (user: User, token: Token) {

        let user = try create(
            email: email,
            pass: pass,
            firstName: firstName,
            lastName: lastName,
            organizationName: organizationName,
            image: image
        )

        let token = try login(email: email, pass: pass)

        return (user, token)
    }
}
