import Console
import Node

public func group(_ console: ConsoleProtocol) -> Group {
    return Group(
        id: "cloud",
        commands: [
            Login(console: console),
            Logout(console: console),
            Signup(console: console),
            Me(console: console),
            Refresh(console: console),
            TokenCommand(console: console),
            Organizations(console: console),
            Projects(console: console),
            Applications(console: console),
        ],
        help: [
            "Commands for interacting with Vapor Cloud."
        ]
    )
}

public final class Login: Command {
    public let id = "login"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you into Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let email = arguments.option("email") ?? console.ask("Email: ")
        let pass = arguments.option("pass") ?? console.ask("Password: ")

        let loginBar = console.loadingBar(title: "Logging in", animated: !arguments.flag("verbose"))
        loginBar.start()
        do {
            let token = try adminApi.login(email: email, pass: pass)
            try token.saveGlobal()
            loginBar.finish()
            console.success("Welcome back.")
        } catch {
            console.warning("Failed to login user")
            console.warning("User 'vapor cloud signup' if you don't have an account")
            loginBar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class Logout: Command {
    public let id = "logout"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs you out of Vapor Cloud."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let bar = console.loadingBar(title: "Logging out")
        bar.start()
        do {
            if FileManager.default.fileExists(atPath: tokenPath) {
                _ = try DataFile.delete(at: tokenPath)
            }
            bar.finish()
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class TokenCommand: Command {
    public let id = "token"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Cached token metadata for debugging."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let limit = 25
        let token = try Token.global(with: console)
        let access: String
        if arguments.flag("full") {
            access = token.access
        } else {
            access = token.access
                .makeBytes()
                .prefix(limit)
                .makeString()
                + "..."
        }

        console.info("Access: ", newLine: false)
        console.print(access)

        let refresh: String
        if arguments.flag("full") {
            refresh = token.refresh
        } else {
            refresh = token.refresh
                .makeBytes()
                .prefix(limit)
                .makeString() + "..."
        }
        console.info("Refresh: ", newLine: false)
        console.print(refresh)

        console.info("Expiration: ", newLine: false)
        let expiration = token.expiration.timeIntervalSince1970 - Date().timeIntervalSince1970
        if expiration >= 0 {
            console.success("\(expiration) seconds from now.")
        } else {
            console.warning("\(expiration * -1) seconds ago.")
        }
    }
}

// TODO: Cache info about current user?
public final class Me: Command {
    public let id = "me"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Shows info about the currently logged in user"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) {
        do {
            let token = try Token.global(with: console)
            let bar = console.loadingBar(title: "Fetching User")
            bar.start()
            do {
                let user = try adminApi.user.get(with: token)
                bar.finish()

                console.success("Name: ", newLine: false)
                console.print("\(user.firstName) \(user.lastName)")
                console.success("Email: ", newLine: false)
                console.print("\(user.email)")

                guard arguments.flag("id") else { return }
                console.success("Id: ", newLine: false)
                console.print("\(user.id.uuidString)")
            } catch {
                bar.fail()
                console.error("Error: \(error)")
                exit(1)
            }
        } catch {
            console.info("No user currently logged in.")
            console.warning("Use 'vapor cloud login' or")
            console.warning("Create an account with 'vapor cloud signup'")
            console.error("Error: \(error)")
        }
    }
}

public final class Refresh: Command {
    public let id = "refresh"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Refreshes vapor token, only while testing, will automate soon."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let bar = console.loadingBar(title: "Refreshing Token")
        bar.start()
        do {
            try adminApi.access.refresh(token)
            try token.saveGlobal()
            bar.finish()
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

// TODO: Paging
public final class Organizations: Command {
    public let id = "organizations"

    public let signature: [Argument] = []

    public let help: [String] = [
        // Should be a group
        "Logs all organizations"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)

        let arguments = arguments.dropFirst().values
        guard !arguments.isEmpty || arguments.first == "list" else {
            print("listing")
            try list(with: token)
            exit(0)
        }

        let command = arguments[0]
        if command == "create" {
            guard arguments.count > 1 else { throw "Invalid signature" }
            let name = arguments[1]
            let bar = console.loadingBar(title: "Creating \(name) Organization")
            do {
                let organization = try adminApi.organizations.create(name: name, with: token)
                bar.finish()
                console.info("\(organization.name): ", newLine: false)
                console.print("\(organization.id)")
            } catch {
                bar.fail()
                console.error("Error: \(error)")
            }
        }
    }

    private func list(with token: Token) throws {
        let bar = console.loadingBar(title: "Fetching Organizations")
        bar.start()
        do {
            let organizations = try adminApi.organizations.all(with: token)
            bar.finish()

            organizations.forEach { organization in
                console.info("- \(organization.name): ", newLine: false)
                console.print("\(organization.id)")
            }
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }

    }
}


public final class Projects: Command {
    public let id = "projects"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Interact w/ your vapor projects"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        try list(with: token)
    }

    private func list(with token: Token) throws {
        let bar = console.loadingBar(title: "Fetching Projects")
        bar.start()
        do {
            let projects = try adminApi.projects.all(with: token)

            var organizationGroup = [UUID: [Project]]()
            projects.forEach { proj in
                var array = organizationGroup[proj.organizationId] ?? []
                array.append(proj)
                organizationGroup[proj.organizationId] = array
            }
            bar.finish()

            organizationGroup.forEach { org, projects in
                console.success("Org: \(org)")
                projects.forEach { organization in
                    console.info("- \(organization.name): ", newLine: false)
                    console.print("\(organization.id)")
                }
            }
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }
    }
}

public final class Applications: Command {
    public let id = "applications"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Logs applications."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let token = try Token.global(with: console)
        let projects = try adminApi.projects.all(with: token)
        let project = try console.giveChoice(title: "Choose Project", in: projects)
        let applications = try applicationApi.get(for: project, with: token)
        applications.forEach { app in
            console.info("\(app)")
        }
    }
}

public final class Signup: Command {
    public let id = "signup"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Creates a new Vapor Cloud user."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let email = console.ask("Email: ")
        let pass = console.ask("Password: ")
        let firstName = console.ask("First Name: ")
        let lastName = console.ask("Last Name: ")
        let organization = "My Cloud"

        let bar = console.loadingBar(title: "Creating User")
        bar.start()
        do {
            try adminApi.create(
                email: email,
                pass: pass,
                firstName: firstName,
                lastName: lastName,
                organizationName: organization,
                image: nil
            )
            bar.finish()
            console.success("Welcome to Vapor Cloud.")
        } catch {
            bar.fail()
            throw "Error: \(error)"
        }

        guard console.confirm("Would you like to login now?") else { return }
        let login = Login(console: console)

        var arguments = arguments
        arguments.append("--email=\(email)")
        arguments.append("--pass=\(pass)")
        try login.run(arguments: arguments)
    }
}

import Core
import JSON
import Foundation
import Vapor

// TODO: Get home directory
let vaporConfigDir = "\(NSHomeDirectory())/.vapor"
let tokenPath = "\(vaporConfigDir)/token.json"

extension Token {
    func saveGlobal() throws {
        try FileManager.default.createVaporConfigFolderIfNecessary()

        var json = JSON([:])
        try json.set("access", access)
        try json.set("refresh", refresh)
        try json.set("expiration", expiration.timeIntervalSince1970)

        let bytes = try json.serialize()
        try DataFile.save(bytes: bytes, to: tokenPath)
    }

    static func global(with console: ConsoleProtocol) throws -> Token {
        let raw = try Node.loadContents(path: tokenPath)
        guard
            let access = raw["access"]?.string,
            let refresh = raw["refresh"]?.string,
            let timestamp = raw["expiration"]?.double
            else {
                console.info("No user currently logged in.")
                console.warning("Use 'vapor cloud login' or")
                console.warning("Create an account with 'vapor cloud signup'")
                exit(1)
            }

        let expiration = Date(timeIntervalSince1970: timestamp)
        let token = Token(access: access, refresh: refresh, expiration: expiration)
        token.didUpdate = { t in
            do {
                try t.saveGlobal()
            } catch {
                print("Failed to save updated token: \(error)")
            }
        }
        return token
    }
}


extension Node {
    /**
     Load the file at a path as raw bytes, or as parsed JSON representation
     */
    fileprivate static func loadContents(path: String) throws -> Node {
        let data = try DataFile().load(path: path)
        guard path.hasSuffix(".json") else { return .bytes(data) }
        return try JSON(bytes: data).converted()
    }
}

extension FileManager {
    func createVaporConfigFolderIfNecessary() throws {
        var isDirectory: ObjCBool = false
        fileExists(atPath: vaporConfigDir, isDirectory: &isDirectory)
        guard !isDirectory.boolValue else { return }
        try createDirectory(atPath: vaporConfigDir, withIntermediateDirectories: true)
    }
}

extension ConsoleProtocol {
    func giveChoice<T>(title: String, in array: [T]) throws -> T {
        let list = array.map { "\($0)" }
        guard
            let selection = askList(withTitle: title, from: list),
            let idx = list.index(of: selection)
            else { throw "Invalid selection" }

        return array[idx]
    }
}
