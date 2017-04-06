import HTTP
import Vapor
import Foundation
import Node
import JSON

public let applicationApi = ApplicationApi()

public struct Application: NodeInitializable {
    public let id: UUID
    public let name: String
    public let projectId: UUID
    public let repo: String

    public init(node: Node) throws {
        id = try node.get("id")
        name = try node.get("name")
        projectId = try node.get("project.id")
        repo = try node.get("repoName")
    }
}

extension Application: Equatable {}

public func == (lhs: Application, rhs: Application) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.projectId == rhs.projectId
        && lhs.repo == rhs.repo
}

public final class ApplicationApi {
    // TODO: Make Internal
    internal static var base = "https://api.vapor.cloud/application"
    internal static let applicationsEndpoint = "\(base)/applications"

    public let hosting = HostingApi()
    public let deploy = DeployApi()
    // TODO: Should be off of hosting, these are hosting environments, not global
    @available(*, deprecated: 1.0, renamed: "hosting.environments")
    public let environments = EnvironmentsApi()
}

extension ApplicationApi {
    public func create(
        for project: Project,
        repo: String,
        name: String,
        with token: Token
    ) throws -> Application {
        let request = try Request(method: .post, uri: ApplicationApi.applicationsEndpoint)
        request.access = token

        var json = JSON([:])
        try json.set("project.id", project.id.uuidString)
        try json.set("repoName", repo)
        try json.set("name", name)
        request.json = json

        let response = try client.respond(to: request)
        return try Application(node: response.json)
    }

//    public func get(forRepo repo: String, with token: Token) throws -> Application? {
//        let projects = try adminApi.projects.all(with: token)
//        return try projects.lazy
//            .flatMap { proj in
//                let apps = try applicationApi.get(for: proj, with: token)
//                return apps
//                    .lazy
//                    .filter { app in app.repo == repo }
//                    .first
//            }
//            .first
//    }

    public func get(for project: Project, with token: Token) throws -> [Application] {
        let endpoint = ApplicationApi.applicationsEndpoint + "?projectId=\(project.id.uuidString)"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request)
        return try [Application](node: response.json?["data"])
    }

    public func get(forGit git: String, with token: Token) throws -> [Application] {
        let endpoint = ApplicationApi.applicationsEndpoint
            + "?hosting:gitUrl=\(git)"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token
        let response = try client.respond(to: request)
        return try [Application](node: response.json?["data"])
    }

    // TODO: See if we can add call on backend that doesn't require subcalls
    public func all(with token: Token) throws -> [Application] {
        let projects = try adminApi.projects.all(with: token)
        return try projects.flatMap { project in
            return try applicationApi.get(for: project, with: token)
        }
    }
}

public struct Hosting: NodeInitializable {
    public let id: UUID
    public let gitUrl: String
    public let applicationId: UUID

    public init(node: Node) throws {
        id = try node.get("id")
        gitUrl = try node.get("gitUrl")
        applicationId = try node.get("application.id")
    }
}

extension Hosting: Equatable {}

public func == (lhs: Hosting, rhs: Hosting) -> Bool {
    return lhs.id == rhs.id
    && lhs.gitUrl == rhs.gitUrl
    && lhs.applicationId == rhs.applicationId
}

extension ApplicationApi {
    public final class HostingApi {
        let environments = EnvironmentsApi()

        // TODO: git expects ssh url, ie: git@github.com:vapor/vapor.git
        public func create(for application: Application, git: String, with token: Token) throws -> Hosting {
            let endpoint = applicationsEndpoint.finished(with: "/") + application.repo + "/hosting"
            let request = try Request(method: .post, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("gitUrl", git)
            request.json = json
            
            let response = try client.respond(to: request)
            return try Hosting(node: response.json)
        }
        
        public func get(forRepo repo: String, with token: Token) throws -> Hosting {
            let endpoint = applicationsEndpoint.finished(with: "/") + repo + "/hosting"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try Hosting(node: response.json)
        }

        public func update(for application: Application, git: String, with token: Token) throws -> Hosting {
            let endpoint = applicationsEndpoint.finished(with: "/") + application.repo + "/hosting"
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("gitUrl", git)
            request.json = json

            let response = try client.respond(to: request)
            return try Hosting(node: response.json)
        }
    }
}

public struct Environment: NodeInitializable {
    public let hostingId: UUID
    public let branch: String
    public let id: UUID
    public let name: String
    public let running: Bool
    public let replicas: Int

    public init(node: Node) throws {
        hostingId = try node.get("hosting.id")
        branch = try node.get("defaultBranch")
        id = try node.get("id")
        name = try node.get("name")
        running = try node.get("running")
        replicas = try node.get("replicas")
    }
}

extension Environment: Equatable {}
public func == (lhs: Environment, rhs: Environment) -> Bool {
    return lhs.hostingId == rhs.hostingId
        && lhs.branch == rhs.branch
        && lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.running == rhs.running
        && lhs.replicas == rhs.replicas
}

extension ApplicationApi {
    // TODO: ALl w/ forRepo instead of app

    public final class EnvironmentsApi {
        let configs = ConfigsApi()

        public func create(
            forRepo repo: String,
            name: String,
            branch: String,
            with token: Token
        ) throws -> Environment {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + repo + "/hosting/environments"
            let request = try Request(method: .post, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name)
            try json.set("defaultBranch", branch)
            request.json = json

            let response = try client.respond(to: request)
            return try Environment(node: response.json)
        }

        public func setReplicas(count: Int, forRepo repo: String, env: Environment, with token: Token) throws -> Environment {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.name
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("replicas", count)
            request.json = json

            let response = try client.respond(to: request)
            return try Environment(node: response.json)
        }

        public func all(for application: Application, with token: Token) throws -> [Environment] {
            return try all(forRepo: application.repo, with: token)
        }

        public func all(forRepo repo: String, with token: Token) throws -> [Environment] {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + repo + "/hosting/environments"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try [Environment](node: response.json)
        }
    }
}

public struct Config: NodeInitializable {
    public let id: UUID
    public let key: String
    public let value: String
    public let environmentId: UUID

    public init(node: Node) throws {
        id = try node.get("id")
        key = try node.get("key")
        value = try node.get("value")
        environmentId = try node.get("environment.id")
    }
}

extension ApplicationApi {
    public final class ConfigsApi {
        func get(forRepo repo: String, envName env: String, with token: Token) throws -> [Config] {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.finished(with: "/")
                + "configurations"

            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try [Config](node: response.json)
        }

        func add(_ configs: [String: String], forRepo repo: String, envName env: String, with token: Token) throws {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.finished(with: "/")
                + "configurations"

            let request = try Request(method: .patch, uri: endpoint)
            request.access = token
            request.json = try JSON(node: configs)

            let response = try client.respond(to: request)
            print(response)
            print("")
        }
    }
}


public struct Deploy: NodeInitializable {
    public let hosting: Hosting
    public let defaultBranch: String
    // TODO: Rename deployOperations or operations
    public let deployments: [Deployment]
    public let id: UUID
    public let name: String
    public let replicas: Int
    public let running: Bool

    public init(node: Node) throws {
        hosting = try node.get("hosting")
        defaultBranch = try node.get("defaultBranch")
        deployments = try node.get("deployments")
        id = try node.get("id")
        name = try node.get("name")
        replicas = try node.get("replicas")
        running = try node.get("running")
    }
}

public struct Git: NodeInitializable {
    public let branch: String
    public let url: String

    public init(node: Node) throws {
        branch = try node.get("branch")
        url = try node.get("url")
    }
}

public enum DeployType: String, NodeInitializable {
    case scale, code

    public init(node: Node) throws {
        guard
            let string = node.string,
            let new = DeployType(rawValue: string)
            else {
                throw NodeError.unableToConvert(input: node, expectation: "String", path: [])
        }
        self = new
    }
}

// TODO: Rename, DeployOperation
public struct Deployment: NodeInitializable {
    public let repo: String
    public let environment: String
    public let git: Git
    public let id: UUID
    public let replicas: Int
    public let status: String
    public let version: String
    public let domains: [String]
    public let type: DeployType

    public init(node: Node) throws {
        repo = try node.get("environment.application.repoName")
        environment = try node.get("environment.name")
        git = try node.get("git")
        id = try node.get("id")
        replicas = try node.get("replicas")
        status = try node.get("status")
        type = try node.get("type.name")
        version = try node.get("version")
        domains = try node.get("domains")
    }
}

public enum BuildType: String {
    static let all: [BuildType] = [.incremental, .update, .clean]
    
    case clean, incremental, update
}

enum DeployError: Error {
    case noHosting(for: Application?)
}

extension ApplicationApi {
    public final class DeployApi {
        public func push(
            repo: String,
            envName: String,
            gitBranch: String?,
            replicas: Int?,
            code: BuildType,
            with token: Token
            ) throws -> Deploy {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + envName
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("code", code.rawValue)
            if let replicas = replicas {
                try json.set("replicas", replicas)
            }
            if let branch = gitBranch {
                try json.set("gitBranch", branch)
            }
            request.json = json

            let response = try client.respond(to: request)
            if
                response.status == .badRequest,
                response.json?["reason"]?.string == "No hosting exists for this application." {
                throw DeployError.noHosting(for: nil)
            }

            return try Deploy(node: response.json)
        }

        public func scale(repo: String, envName: String, replicas: Int, with token: Token) throws {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + envName
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("replicas", replicas)
            request.json = json
        }
    }
}
