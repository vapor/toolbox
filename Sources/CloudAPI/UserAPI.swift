import Vapor

public struct CloudUser: Content {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let email: String
}

/// The User API is a specialized resource access controller
/// since most of its endpoints have specialized
/// functionality
public struct UserApi {
    public static func signup(
        email: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        password: String
    ) throws -> CloudUser {
        struct Package: Content {
            let email: String
            let firstName: String
            let lastName: String
            let organizationName: String
            let password: String
        }
        let content = Package(
            email: email,
            firstName: firstName,
            lastName: lastName,
            organizationName: organizationName,
            password: password
        )

        let client = try makeClient()
        let response = client.send(.POST, to: userUrl) { try $0.content.encode(content) }
        return try response.become(CloudUser.self)
    }

    public static func login(
        email: String,
        password: String
    ) throws -> Token {
        let combination = email + ":" + password
        let data = combination.data(using: .utf8)!
        let encoded = data.base64EncodedString()

        let headers: HTTPHeaders = [
            "Authorization": "Basic \(encoded)"
        ]
        let client = try makeClient()
        let response = client.send(.POST, headers: headers, to: loginUrl)
        return try response.become(Token.self)
    }

    public static func me(token: Token) throws -> CloudUser {
        let access = CloudUser.Access(with: token, baseUrl: meUrl)
        return try access.view()
    }

    public static func reset(email: String) throws {
        struct Package: Content {
            let email: String
        }
        let content = Package(email: email)
        let client = try makeClient()
        let response = client.send(.POST, to: resetUrl) { try $0.content.encode(content) }
        try response.validate()
    }
}
