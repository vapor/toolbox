/*

 Current Issues

 - View on a region w/ ID replies "Region not found"

 */

import Vapor

struct CloudGroup: CommandGroup {
    let commands: Commands = [
        // global context
        "login" : CloudLogin(),
        "signup": CloudSignup(),
        "me": Me(),
        "dump-token": DumpToken(),
        "ssh": CloudSSHGroup(),
        "apps": CloudAppsGroup(),
        "orgs": CloudOrgsGroup(),
        "envs": CloudEnvsGroup(),
        // current or no context
        "deploy": CloudDeploy(),
        // current context
        "detect": detectApplication,
        "set-remote": cloudSetRemote,
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
    internal var trailSlash: String { return finished(with: "/") }
}

let cloudBaseUrl = "https://api.v2.vapor.cloud/v2/"
let gitUrl = cloudBaseUrl.trailSlash + "git"
let gitSSHKeysUrl = gitUrl.trailSlash + "keys"
let authUrl = cloudBaseUrl.trailSlash + "auth"
let resetUrl = authUrl.trailSlash + "reset"
let userUrl = authUrl.trailSlash + "users"
let loginUrl = userUrl.trailSlash + "login"
let meUrl = userUrl.trailSlash + "me"

let applicationsUrl = appsUrl.trailSlash + "applications"
let appsUrl = cloudBaseUrl.trailSlash + "apps"
let environmentsUrl = appsUrl.trailSlash + "environments"
let organizationsUrl = authUrl.trailSlash + "organizations"
let regionsUrl = appsUrl.trailSlash + "regions"
let plansUrl = appsUrl.trailSlash + "plans"
let productsUrl = appsUrl.trailSlash + "products"
let activitiesUrl = cloudBaseUrl.trailSlash + "activity/activities"

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

func makeWebSocketClient(url: URLRepresentable) throws -> Future<WebSocket> {
    return try makeClient().webSocket(url)
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

public func fooBar() throws {
    return
//    let token = try Token.load()
//    let access = [String: String].Access(with: token, baseUrl: activitiesUrl)
//    let apps = try access.list()
//    print(apps)
//    print("")
//    let activityId = ""
//    let activity =
//    "wss://api.v2.vapor.cloud/v2/activity/activities/\(activityId)/channel"
    let echo = "wss://api-activity.v2.vapor.cloud/echo-test"
//    let echo = "wss://sandbox.kaazing.net/echo"
//    let echo = "ws://localhost:8080/echo-test"
    let ws = try makeWebSocketClient(url: echo).wait()

    var count = 5
    ws.onText { ws, text in
        print("Got: \(text)")
        sleep(3)
        ws.send("more")
        count -= 1
        if count == 0 {
            ws.close()
        }
    }

    ws.send("start")

    // stay open
    try ws.onClose.wait()
    print("Closed")
    print("")
//    let token = try Token.load()
//    let access = [String: String].Access(with: token, baseUrl: activitiesUrl)
//    let apps = try access.list()
//    let mapped = apps.map { try! $0.printable() }
//    mapped.forEach { mapp in
//        print(mapp)
//    }
//    print("")
}

extension Content {
    func printable() throws -> ConsoleText {
        let data = try JSONEncoder().encode(self)
        let possible = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let obj = possible else { throw "not an object" }
        var value = ""
        obj.sorted { $0.key < $1.key }.forEach { (key, val) in
            value += key.capitalized
            value += ":\n"
            value += "  \(val)"
            value += "\n"
        }
        return value.consoleText()
    }
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

struct Activity: Content {
    let id: UUID
}

struct CloudEnv: Content {
    let defaultBranch: String
    let applicationID: UUID
    let createdAt: Date?
    let id: UUID
    let slug: String
    let regionID: UUID
    let updatedAt: Date?
    let activity: Activity?
}

//{"slug":"production","applicationID":"E8ED0C82-2C7D-40C7-9603-29FD337393EA","regionID":"9E18D12A-40D9-46BD-8D43-1FD4D1BFDF15","defaultBranch":"master","activity":{"id":"508C9D1A-2F64-472F-9053-2FC040AA1787"},"id":"127D4299-8CA8-42FC-A09C-B3F675971419"}

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

    func list(query: String? = nil) throws -> [T] {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = try send(.GET, to: url)
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
//        print(try! response.wait())
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
//        print(try! response.wait())
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

struct Simple: MyCommand {
    /// See `Command`.
    let arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = []

    let runner: (CommandContext) throws -> Void

    init(runner: @escaping (CommandContext) throws -> Void) {
        self.runner = runner
    }

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        try runner(ctx)
    }
}

let listOrganizations = Simple { ctx in
    let token = try Token.load()
    let access = Organization.Access(with: token, baseUrl: organizationsUrl)
    let orgs = try access.list()
    ctx.console.log(orgs)
}

let listEnvironments = Simple { ctx in
    let token = try Token.load()

    let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
    let apps = try access.list()
    let app = ctx.console.choose("Which App?", from: apps) { app in
        return app.name.consoleText()
    }
    let url = applicationsUrl.trailSlash + app.id.uuidString.trailSlash + "environments"
    let envAccess = CloudEnv.Access(with: token, baseUrl: url)
    let envs = try envAccess.list()
    ctx.console.log(envs)
}


let deployEnvironment = Simple { ctx in
    let token = try Token.load()

    let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
    let apps = try access.list()
    let app = ctx.console.choose("Which App?", from: apps) { app in
        return app.name.consoleText()
    }
    let appEnvsUrl = applicationsUrl.trailSlash + app.id.uuidString.trailSlash + "environments"
    let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
    let envs = try envAccess.list()
    let env = ctx.console.choose("Which Env?", from: envs) { env in
        return env.slug.consoleText()
    }


    let deployAccess = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
    let updated = try deployAccess.update(
        id: env.id.uuidString.trailSlash + "deploy",
        with: [String: String]()
    )
    print(updated.activity?.id.uuidString ?? "<error>")

    guard let activity = updated.activity else { throw "no activity returned" }
    let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
//    let wssUrl = "wss://sandbox.kaazing.net/echo"
    print("Connecting to: \(wssUrl)")
    let ws = try makeWebSocketClient(url: wssUrl).wait()
    print("connected")
    ws.onText { ws, text in
        print("got text: \(text)")
    }
    try ws.onClose.wait()
    print("Web socket closed")

//
//    let done = wss.flatMap { ws -> Future<Void> in
//        print("Connected ws: \(ws)")
//        // setup an on text callback that will print the echo
//        ws.onText { ws, text in
//            print("rec: \(text)")
//            // close the websocket connection after we recv the echo
////            ws.close()
//            sleep(3)
//            ws.send("foo")
//        }
//
//        ws.onBinary { ws, data in
//            print("Some data tho: \(data)")
//        }
//
//        // when the websocket first connects, send message
////        ws.send("hello, world!")
//
//        // return a future that will complete when the websocket closes
//        return ws.onClose
//    }
//    try done.wait()
//    print(done)
////    let deployUrl = environmentsUrl.trailSlash + env.id.uuidString.trailSlash + "deploy"
////    let deploy = [String: String].Access(with: token, baseUrl: deployUrl)
////    let updated = try deploy.update(id: env.id.uuidString, with: [String: String]())
//    print(updated)
//    print("")
//    ctx.console.output("Deployed \(updated.slug)".consoleText())

}

let listApplications = Simple { ctx in
    let token = try Token.load()
    let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
    let apps = try access.list()
    ctx.console.log(apps)
}

let detectApplication = Simple { ctx in
    let app = try ctx.detectCloudApp()
    ctx.console.log(app)
}

extension CommandContext {
    func detectCloudApp() throws -> CloudApp {
        let token = try Token.load()
        let cloudGitUrl = try Git.cloudUrl()

        let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
        let apps = try access.list(query: "gitURL=\(cloudGitUrl)")
        guard apps.count == 1 else { throw "No app found at \(cloudGitUrl)." }
        return apps[0]
    }
}

//func detectApp(ctx: CommandContext) throws -> CloudApp {
//}

extension Console {
    func log<C: Content>(_ c: C) {
        // TODO: throw
        let p = try! c.printable()
        output(p)
    }
    func log<C: Content>(_ c: [C]) {
        c.forEach(log)
    }
}

struct CloudOrgsGroup: CommandGroup {
    let commands: Commands = [
        "list" : listOrganizations,
    ]

    /// See `CommandGroup`.
    let options: [CommandOption] = []

    /// See `CommandGroup`.
    var help: [String] = [
        "Interact with Vapor Cloud Orgs"
    ]

    /// See `CommandGroup`.
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        // should never run
        throw "should not run"
    }
}

struct CloudAppsGroup: CommandGroup {
    let commands: Commands = [
        "list" : listApplications,
    ]

    /// See `CommandGroup`.
    let options: [CommandOption] = []

    /// See `CommandGroup`.
    var help: [String] = [
        "Interact with Vapor Cloud Applications"
    ]

    /// See `CommandGroup`.
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        // should never run
        throw "should not run"
    }
}

struct CloudEnvsGroup: CommandGroup {
    let commands: Commands = [
        "list" : listEnvironments,
    ]

    /// See `CommandGroup`.
    let options: [CommandOption] = []

    /// See `CommandGroup`.
    var help: [String] = [
        "Interact with Vapor Cloud Environments"
    ]

    /// See `CommandGroup`.
    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        // should never run
        throw "should not run"
    }
}

let cloudSetRemote = Simple { ctx in
    let isGit = Git.isGitRepository()
    guard isGit else {
        throw "Not currently in a git repository."
    }

    let isConfigured = try Git.isCloudConfigured()
    guard !isConfigured else {
        throw "Cloud is already configured."
    }

    let token = try Token.load()
    let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
    let apps = try access.list()
    let app = ctx.console.choose("Which app?", from: apps) {
        return $0.name.consoleText()
    }

    try Git.setRemote(named: "cloud", url: app.gitURL)
    ctx.console.output("Cloud repository configured.")
}


func build(ctx: CommandContext) throws {
    // Ensure logged in
    let token = try Token.load()


    let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
    let apps = try access.list()
    let app = ctx.console.choose("Which App?", from: apps) { app in
        return app.name.consoleText()
    }
    let appEnvsUrl = applicationsUrl.trailSlash + app.id.uuidString.trailSlash + "environments"
    let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
    let envs = try envAccess.list()
    let env = ctx.console.choose("Which Env?", from: envs) { env in
        return env.slug.consoleText()
    }


    let deployAccess = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
    let updated = try deployAccess.update(
        id: env.id.uuidString.trailSlash + "deploy",
        with: [String: String]()
    )
    print(updated.activity?.id.uuidString ?? "<error>")

    guard let activity = updated.activity else { throw "no activity returned" }
    let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
    //    let wssUrl = "wss://sandbox.kaazing.net/echo"
    print("Connecting to: \(wssUrl)")
    let ws = try makeWebSocketClient(url: wssUrl).wait()
    print("connected")
    ws.onText { ws, text in
        print("got text: \(text)")
    }
    try ws.onClose.wait()
    print("Web socket closed")

    //
    //    let done = wss.flatMap { ws -> Future<Void> in
    //        print("Connected ws: \(ws)")
    //        // setup an on text callback that will print the echo
    //        ws.onText { ws, text in
    //            print("rec: \(text)")
    //            // close the websocket connection after we recv the echo
    ////            ws.close()
    //            sleep(3)
    //            ws.send("foo")
    //        }
    //
    //        ws.onBinary { ws, data in
    //            print("Some data tho: \(data)")
    //        }
    //
    //        // when the websocket first connects, send message
    ////        ws.send("hello, world!")
    //
    //        // return a future that will complete when the websocket closes
    //        return ws.onClose
    //    }
    //    try done.wait()
    //    print(done)
    ////    let deployUrl = environmentsUrl.trailSlash + env.id.uuidString.trailSlash + "deploy"
    ////    let deploy = [String: String].Access(with: token, baseUrl: deployUrl)
    ////    let updated = try deploy.update(id: env.id.uuidString, with: [String: String]())
    //    print(updated)
    //    print("")
    //    ctx.console.output("Deployed \(updated.slug)".consoleText())

}
