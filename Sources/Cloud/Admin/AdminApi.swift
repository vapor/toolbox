import HTTP
import Vapor

public final class AdminApi {
    internal static let base = "https://admin-api-staging.vapor.cloud/admin"
    internal static let usersEndpoint = "\(base)/users"
    internal static let loginEndpoint = "\(base)/login"
    internal static let meEndpoint = "\(base)/me"
    internal static let refreshEndpoint = "\(base)/refresh"
    internal static let organizationsEndpoint = "\(base)/organizations"
    internal static let projectsEndpoint = "\(base)/projects"

    // client
    internal static let client = EngineClient.self

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
    public func create(email: String, pass: String, firstName: String, lastName: String, organizationName: String, image: String?) throws -> Response {
        var json = JSON([:])
        try json.set("email", email)
        try json.set("password", pass)
        try json.set("name.first", firstName)
        try json.set("name.last", lastName)
        try json.set("organization.name", organizationName)
        if let image = image {
            try json.set("image", image)
        }

        let request = try Request(method: .post, uri: AdminApi.usersEndpoint)
        request.json = json

        return try AdminApi.client.respond(to: request, through: middleware)
    }

    public func login(email: String, pass: String) throws -> Token {
        var json = JSON([:])
        try json.set("email", email)
        try json.set("password", pass)

        let request = try Request(method: .post, uri: AdminApi.loginEndpoint)
        request.json = json
        let response = try AdminApi.client.respond(to: request, through: middleware)
        guard
            let access = response.json?["accessToken"]?.string,
            let refresh = response.json?["refreshToken"]?.string
            else { throw "Bad response to login: \(response)" }

        return Token(access: access, refresh: refresh)
    }
}
