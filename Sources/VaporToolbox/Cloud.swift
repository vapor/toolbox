import Vapor

public func testCloud() throws {
    try signup()
}

let cloudBaseUrl = "https://api.v2.vapor.cloud/"
let authUrl = cloudBaseUrl + "v2/auth/"
let userUrl = authUrl + "users"
let loginUrl = userUrl.finished(with: "/") + "login"
let meUrl = userUrl.finished(with: "/") + "me"

struct CloudUser: Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
}

struct UserApi {
    static func signup(
        email: String,
        firstName: String,
        lastName: String,
        organizationName: String,
        password: String
    ) throws -> CloudUser {
        struct NewUser: Content {
            let email: String
            let firstName: String
            let lastName: String
            let organizationName: String
            let password: String
        }

        let content = NewUser(
            email: email,
            firstName: firstName,
            lastName: lastName,
            organizationName: organizationName,
            password: password
        )

        let client = try makeClient()
        let response = client.send(.POST, to: userUrl) { try $0.content.encode(content) }
        return try response.wait().content.decode(CloudUser.self).wait()
    }

    static func login(
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
        return try response.wait().content.decode(Token.self).wait()
    }

    static func me(token: Token) throws -> CloudUser {
        let client = try makeClient()
        let headers = token.headers
        let response = client.send(.GET, headers: headers, to: meUrl)
        let resp = try response.wait()
        print(resp)
        return try resp.content.decode(CloudUser.self).wait()
    }
}

struct Token: Content {
    let expiresAt: Date
    let id: UUID
    let userID: UUID
    let token: String
}

extension Token {
    var headers: HTTPHeaders {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}


func signup() throws {
    let email = "logan+\(Date().timeIntervalSince1970)@gmail.com"
    let pwd = "12Three!"
    let new = try UserApi.signup(
        email: email,
        firstName: "Test",
        lastName: "Tester",
        organizationName: "TestOrg",
        password: pwd
    )
    print("new: \(new)")
    let token = try UserApi.login(email: email, password: pwd)
    print(token)
    let me = try UserApi.me(token: token)
    print(me)
    print("")
//    let response = try client.post(signUpUrl, headers: HTTPHeaders(), content: new).wait()
//    print(response)
//    print("")
}

func makeClient() throws -> Client {
    return try Request(using: app).make()
}

let app: Application = {
    var config = Config.default()
    var env = try! Environment.detect()
    var services = Services.default()

    let app = try! Application(
        config: config,
        environment: env,
        services: services
    )

    return app
}()
