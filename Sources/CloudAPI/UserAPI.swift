import Vapor
import Globals

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

    public init() {}

    public func signup(
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
        
        let req = try ClientRequest(method: .POST, to: userUrl, body: content)
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
//        let client = makeClient()
        let req = try ClientRequest(method: .POST, to: loginUrl, headers: headers)
        let response = try Web.send(req)
        return try response.become(Token.self)//.wait()
    }

    public func me(token: Token) throws -> CloudUser {
        let access = CloudUser.Access(with: token, baseUrl: meUrl)
        return try access.view()
    }

    public func reset(email: String) throws {
        struct Package: Content {
            let email: String
        }
        let content = Package(email: email)
        
        let req = try ClientRequest(method: .POST, to: resetUrl, body: content)
        let _ = try Web.send(req)//.validate().void().wait()
    }
}
