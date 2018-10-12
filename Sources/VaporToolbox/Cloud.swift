import Vapor

/**

 // MARK: User APIs

 vapor cloud login
 - email:
 - pwd:

 vapor cloud signup
 - firstName:
 - lastName:
 - email:
 - pwd:
 - organizationName:

 vapor cloud me

 // MARK: SSH Key APIs

 vapor cloud ssh create (-n name-of-key -p path-to-key)
 // if one key, push

 vapor cloud ssh list
 // list all

 vapor cloud ssh delete name-of-key
 // if multiple names exist, ask which one

 **/

public func testCloud() throws {
    try signup()
}

let cloudBaseUrl = "https://api.v2.vapor.cloud/v2/"
let gitUrl = cloudBaseUrl + "git"
let gitSSHKeysUrl = gitUrl.finished(with: "/") + "keys"
let authUrl = cloudBaseUrl + "auth/"
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
        return try response.become(CloudUser.self)
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
        return try response.become(Token.self)
    }

    static func me(token: Token) throws -> CloudUser {
        let client = try makeClient()
        let headers = token.headers
        let response = client.send(.GET, headers: headers, to: meUrl)
        return try response.become(CloudUser.self)
    }
}

protocol API {
    var token: Token { get }
}

struct SSHKey: Content {
    let key: String
    let name: String
    let userID: UUID

    let id: UUID
    let createdAt: Date
    let updatedAt: Date
}

extension API {
    var basicAuthHeaders: HTTPHeaders {
        return token.headers
    }

    var contentHeaders: HTTPHeaders {
        var head = token.headers
        head.add(name: "Content-Type", value: "application/json")
        return head
    }
}

struct ResponseError: Content, Error {
    let error: Bool
    let reason: String
}

extension Response {
    func throwIfError() throws -> Response {
        if let error = try? content.decode(ResponseError.self).wait() {
            throw error
        } else {
            return self
        }
    }
}

extension Future where T == Response {
    func become<C: Content>(_ type: C.Type) throws -> C {
        return try wait().throwIfError().content.decode(C.self).wait()
    }
}

struct SSHKeyApi: API {
    let token: Token

    func push(name: String, path: String) throws -> SSHKey {
        guard FileManager.default.fileExists(atPath: path) else { throw "no rsa key found at \(path)" }
        guard let file = FileManager.default.contents(atPath: path) else { throw "unable to load rsa key" }
        guard let key = String(data: file, encoding: .utf8) else { throw "no string found in data" }
        return try push(name: name, key: key)
    }

    func push(name: String, key: String) throws -> SSHKey {
        struct Package: Content {
            let name: String
            let key: String
        }
        let package = Package(name: name, key: key)
        let client = try makeClient()
        let response = client.send(.POST, headers: contentHeaders, to: gitSSHKeysUrl) { try $0.content.encode(package) }
        return try response.become(SSHKey.self)
    }

    func list() throws -> [SSHKey] {
        let client = try makeClient()
        let response = client.send(.GET, headers: basicAuthHeaders, to: gitSSHKeysUrl)
        return try response.become([SSHKey].self)
    }

    func delete(_ key: SSHKey) throws {
        let client = try makeClient()
        let url = gitSSHKeysUrl.finished(with: "/") + key.id.uuidString
        let response = client.send(.DELETE, headers: basicAuthHeaders, to: url)
        let _ = try response.wait().throwIfError()
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

func testUserSignupFlow() throws {
    let email = "test.not.real+\(Date().timeIntervalSince1970)@fake.com"
    let pwd = "12ThreeFour!"
    let new = try UserApi.signup(
        email: email,
        firstName: "Test",
        lastName: "Tester",
        organizationName: "TestOrg",
        password: pwd
    )

    // attempt login new user
    let token = try UserApi.login(email: email, password: pwd)

    let me = try UserApi.me(token: token)
    guard
        new.email == me.email,
        new.firstName == me.firstName,
        new.lastName == me.lastName,
        new.id == me.id
        else { throw "failed user signup flow" }
}

func testSSHKey(with token: Token) throws {
    let ssh = SSHKeyApi(token: token)
    let key = try ssh.push(name: "my-key", path: "/Users/loganwright/Desktop/TestKey/id_rsa.pub")
    print(key)
    print("")
}

extension Token {
    static func filePath() throws -> URL {
        let home = try Shell.homeDirectory()
        let vaporDir = home.finished(with: "/") + ".vapor/token"
        guard let url = URL(string: vaporDir) else { throw "unable to make file path" }
        return url
    }

    static func load() throws -> Token {
        let path = try filePath()
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(Token.self, from: data)
    }

    func save() throws {
        let path = try Token.filePath()
        let data = try JSONEncoder().encode(self)
        try data.write(to: path)
    }
}
let testEmail = "logan.william.wright+test.account@gmail.com"
let testPassword = "12ThreeFour!"

func signup() throws {
    let home = try Shell.homeDirectory()
    let vaporDir = home.finished(with: "/") + ".vapor"
    let exists = FileManager.default.fileExists(atPath: vaporDir)
    print("Exists: \(exists)")
    print("")
    let token = try UserApi.login(email: testEmail, password: testPassword)
    print("Got tokenn: \(token)")
    print("")
    try testSSHKey(with: token)
//    print
//
//    let sshApi = SSHKeyApi(token: token)
//    let key = try sshApi.push(name: "my-key", key: "this is not a real key, it's pretend \(Date().timeIntervalSince1970)")
//    print("Made key: \(key)")
//    let allKeys = try sshApi.list()
//    print("Fetched Keys: \(allKeys)")
//    try sshApi.delete(key)
//
//    let afterDelete = try sshApi.list()
//    print("Fetched Keys (After Delete): \(afterDelete)")


    print("")
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
