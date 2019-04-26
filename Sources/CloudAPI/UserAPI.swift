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

    public let container: Container
    public init(on container: Container) {
        self.container = container
    }

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
        
        let req = try ClientRequest(method: .POST, url: userUrl, body: content)
        return try makeClient().send(req).become(CloudUser.self).wait()
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
        let client = makeClient()
        let response = client.send(.POST, headers: headers, to: loginUrl)
        return try response.become(Token.self).wait()
    }

    public func me(token: Token) -> EventLoopFuture<CloudUser> {
        let access = CloudUser.Access(with: token, baseUrl: meUrl)
        return access.view()
    }

    public func reset(email: String) throws {
        struct Package: Content {
            let email: String
        }
        let content = Package(email: email)
        
        let req = try ClientRequest(method: .POST, url: resetUrl, body: content)
        try makeClient().send(req).validate().void().wait()
    }
}
