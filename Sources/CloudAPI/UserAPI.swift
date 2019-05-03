import Foundation
import NIOHTTP1
import NIOHTTPClient
import Globals

public struct CloudUser: Resource {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let email: String
}

/// The User API is a specialized resource access controller
/// since most of its endpoints have specialized
/// functionality
public struct UserApi {

    public init() {}

    public func signup(
        email: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        password: String
    ) throws -> CloudUser {
        struct Package: Encodable {
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
        
        let req = try HTTPClient.Request(url: userUrl, method: .POST, body: .init(content))
        return try Web.send(req).become(CloudUser.self)
    }

    public func login(
        email: String,
        password: String
    ) throws -> Token {
        let combination = email + ":" + password
        let data = combination.data(using: .utf8)!
        let encoded = data.base64EncodedString()

        let headers: HTTPHeaders = [
            "Authorization": "Basic \(encoded)"
        ]
        let req = try HTTPClient.Request(url: loginUrl, method: .POST, headers: headers)
        let response = try Web.send(req)
        return try response.become(Token.self)
    }

    public func me(token: Token) throws -> CloudUser {
        let access = CloudUser.Access(with: token, baseUrl: meUrl)
        return try access.view()
    }

    public func reset(email: String) throws {
        struct Package: Codable {
            let email: String
        }
        let content = Package(email: email)
        
        let req = try HTTPClient.Request(url: resetUrl, method: .POST, body: .init(content))
        let _ = try Web.send(req)
    }
}

extension HTTPClient.Body {
    init<E: Encodable>(_ ob: E) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ob)
        self = .data(data)
    }
}
