/*

 Current Issues

 - View on a region w/ ID replies "Region not found"

 */

import Vapor

struct CloudGroup: CommandGroup {
    let commands: Commands = [
        "login" : CloudLogin(),
        "signup": CloudSignup(),
        "me": Me(),
        "dump-token": DumpToken(),
        "ssh": CloudSSHGroup(),
        "deploy": CloudDeploy(),
    ]

    /// See `CommandGroup`.
    let options: [CommandOption] = []

    /// See `CommandGroup`.
    var help: [String] = [
        "Interact with Vapor Cloud."
    ]

    /// See `CommandGroup`.
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        // should never run
        throw "should not run"
    }
}

protocol MyCommand: Command {
    func trigger(with ctx: CommandContext) throws
}

extension MyCommand {
    /// Throwing errors here logs a bunch of information
    /// about how to use the command, but it clutters
    /// the terminal and isn't relavant to the issue
    ///
    /// Here we eat and print any errors but don't throw from here to avoid
    /// this until a more permanent fix can be found
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        do {
            try trigger(with: ctx)
        } catch {
            ctx.console.output("Error:", style: .error)
            ctx.console.output("\(error)".consoleText())
        }
        return .done(on: ctx.container)
    }
}

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

extension String {
    fileprivate var trailSlash: String { return finished(with: "/") }
}

let cloudBaseUrl = "https://api.v2.vapor.cloud/v2/"
let gitUrl = cloudBaseUrl.trailSlash + "git"
let gitSSHKeysUrl = gitUrl.trailSlash + "keys"
let authUrl = cloudBaseUrl.trailSlash + "auth"
let userUrl = authUrl.trailSlash + "users"
let loginUrl = userUrl.trailSlash + "login"
let meUrl = userUrl.trailSlash + "me"

let applicationsUrl = appsUrl.trailSlash + "applications"
let appsUrl = cloudBaseUrl.trailSlash + "apps"
let environmentsUrl = applicationsUrl.trailSlash + "environments"
let organizationsUrl = authUrl.trailSlash + "organizations"
let regionsUrl = appsUrl.trailSlash + "regions"
let plansUrl = appsUrl.trailSlash + "plans"
let productsUrl = appsUrl.trailSlash + "products"

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
        let access = CloudUser.Access(with: token, baseUrl: meUrl)
        return try access.view()
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

struct ResponseError: Content, Error, CustomStringConvertible {
    let error: Bool
    let reason: String

    var description: String {
        return reason
    }
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

    func validate() throws {
        let _ = try wait().throwIfError()
    }
}

extension Content {
    func resourceAccessor() throws -> CloudResourceAccess<Self> {
        fatalError()
    }
}


protocol CloudResource: Content {
    var id: UUID { get }
}

extension Content {
    static func Access(with token: Token, baseUrl url: String) -> CloudResourceAccess<Self> {
        return CloudResourceAccess<Self>(token: token, baseUrl: url)
    }
}


struct SSHKeyApi: API {
    let token: Token

    var access: CloudResourceAccess<SSHKey> { return SSHKey.Access(with: token, baseUrl: gitSSHKeysUrl) }

    func push(name: String, key: String) throws -> SSHKey {
        struct Package: Content {
            let name: String
            let key: String
        }
        let package = Package(name: name, key: key)
        return try access.create(package)
    }

    func list() throws -> [SSHKey] {
        return try access.list()
    }

    func delete(_ key: SSHKey) throws {
        let keyAccess = CloudResourceAccess<SSHKey>(token: token, baseUrl: gitSSHKeysUrl)
        try keyAccess.delete(id: key.id.uuidString)
    }

    internal func clear() throws {
        let allKeys = try list()
        try allKeys.forEach(delete)
    }
}

struct Token: Content, Hashable {
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
//    let ssh = SSHKeyApi(token: token)
//    let key = try ssh.push(name: "my-key", path: "/Users/loganwright/Desktop/TestKey/id_rsa.pub")
//    print(key)
//    print("")
}

extension Token {
    static func filePath() throws -> String {
        let home = try Shell.homeDirectory()
        return home.finished(with: "/") + ".vapor/token"
    }

    static func load() throws -> Token {
        let path = try filePath()
        let exists = FileManager
            .default
            .fileExists(atPath: path)
        guard exists else { throw "not logged in, use 'vapor cloud login', and try again." }
        let loaded = try FileManager.default.contents(atPath: path).flatMap {
            try JSONDecoder().decode(Token.self, from: $0)
        }
        guard let token = loaded else { throw "error, use 'vapor cloud login', and try again." }
        guard token.isValid else { throw "expired credentials, use 'vapor cloud login', and try again." }
        return token
    }

    func save() throws {
        let path = try Token.filePath()
        let data = try JSONEncoder().encode(self)
        let create = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
        guard create else { throw "there was a problem svaing token" }
    }
}

let testEmail = "logan.william.wright+test.account@gmail.com"
let testPassword = "12ThreeFour!"

func signup() throws {
//    guard let token = try Token.load() else { throw "where's a token, yo" }
//    guard token.isValid else { throw "token is no longer valid" }
//    let sshApi = SSHKeyApi(token: token)
//    print("will clear")
//    try sshApi.clear()
//    print("cleared")
//    print("")

//    let chosenPath = try getPublicKeyPath()
//    print("Chose: \(chosenPath)")
//    let key = try sshApi.push(name: "some-name", path: chosenPath)
//    print("key: \(key)")
//    print("")
}

func getPublicKeyPath() throws -> String {
    let allKeys = try Shell.bash("ls  ~/.ssh/*.pub")
    let separated = allKeys.split(separator: "\n").map(String.init)
    let term = Terminal()
    return term.choose("Which key would you like to push?", from: separated)
}

extension Token {
    var isValid: Bool {
        return !isExpired
    }
    var isExpired: Bool {
        return expiresAt < Date()
    }
}

func asdf() throws {
//    let token = try UserApi.login(email: testEmail, password: testPassword)
//    print("Got tokenn: \(token)")
//    do {
//        print("Testing load not exist")
//        let no = try Token.load()
////        print("Exists? \(no != nil)")
//        print("")
//    } catch {
//        print("caught Error: \(error)")
//        print("")
//    }
//    try token.save()
//    let loaded = try Token.load()
//    print("loaded: \(loaded)")
//    print("equal: \(loaded == token)")
//    print("")
//    try testSSHKey(with: token)
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


func asdfasdf() throws {
    let token = try Token.load()
    let regions = CloudResourceAccess<CloudApp>(token: token, baseUrl: applicationsUrl)
    let list = try regions.list()
    print(list)
    let view = try regions.view(id: list.first!.id.uuidString)
    print(view)
    print("")
}

struct Organization: Content {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date?
    let slug: String
    let name: String
}

struct Region: Content {
    let id: UUID
    let provider: String
    let name: String
    let country: String
}

struct Product: Content {
    let id: UUID
    let name: String
    let slug: String
}

struct Plan: Content {
    let id: UUID
    let name: String
    let slug: String

    let details: [String: Int]
    let description: String
    let price: Double
    let productID: UUID
}

protocol Resource: Content {

}



protocol CreatableResource: Resource {
    associatedtype PostType
}

struct ComplexResourceAccess<T: CreatableResource> {

}

struct CloudResourceAccess<T: Content> {
    let token: Token
    let baseUrl: String

    func view() throws -> T {
        let response = try send(.GET, to: baseUrl)
        return try response.become(T.self)
    }

    func list() throws -> [T] {
        let response = try send(.GET, to: baseUrl)
        return try response.become([T].self)
    }

    func view(id: String) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.GET, to: url)
        return try response.become(T.self)
    }

    func create<U: Content>(_ content: U) throws -> T {
        let response = try send(.POST, to: baseUrl, with: content)
        return try response.become(T.self)
    }

    func update<U: Content>(id: String, with content: U) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PATCH, to: url, with: content)
        return try response.become(T.self)
    }

    func replace(id: String, with content: T) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PUT, to: url, with: content)
        return try response.become(T.self)
    }

    func delete(id: String) throws {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.DELETE, to: url)
        try response.validate()
    }

    private func send<C: Content>(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        with content: C
    )  throws -> Future<Response> {
        return try send(method, to: url) { try $0.content.encode(content) }
    }

    private func send(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        beforeSend: (Request) throws -> () = { _ in }
    ) throws -> Future<Response> {
        // Headers
        var headers = token.headers
        headers.add(name: .contentType, value: "application/json")

        let client = try makeClient()
        let response = client.send(method, headers: headers, to: url, beforeSend: beforeSend)
        return response
    }
}

struct SimpleResourceAccess<T: Content> {
    let token: Token
    let url: String

    func list() throws -> [T] {
        let client = try makeClient()
        var headers = token.headers
        headers.add(name: .contentType, value: "application/json")

        let response = client.send(.GET, headers: headers, to: url)
        print(try response.wait())
        return try response.become([T].self)
    }

    func view(id: String) throws -> T {
        let url = self.url.trailSlash + id

        let client = try makeClient()
        var headers = token.headers
        headers.add(name: .contentType, value: "application/json")

        let response = client.send(.GET, headers: headers, to: url)
        return try response.become(T.self)
    }
}

struct OrganizationsApi {
    let token: Token

    func list() throws -> [Organization] {
        let client = try makeClient()
        let headers = token.headers
        let response = client.send(.GET, headers: headers, to: regionsUrl)
        print(try! response.wait())
        return try response.become([Organization].self)
    }

    func view(id: String) throws -> Organization {
        let url = organizationsUrl.trailSlash + "id"
        let client = try makeClient()
        let headers = token.headers
        let response = client.send(.GET, headers: headers, to: url)
        return try response.become(Organization.self)
    }
}

struct CloudApp: Content {
    let updatedAt: Date
    let name: String
    let createdAt: Date
    let namespace: String
    let github: String?
    let slug: String
    let organizationID: UUID
    let gitURL: String
    let id: UUID
}

struct ApplicationsApi: API {
    let token: Token

    func list() throws -> [CloudApp] {
        let client = try makeClient()
        let headers = token.headers
        let response = client.send(.GET, headers: headers, to: applicationsUrl)
        return try response.become([CloudApp].self)
    }
}

