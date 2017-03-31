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
    public static let base = "https://api.vapor.cloud/application"
    public static let applicationsEndpoint = "\(base)/applications"

    public let hosting = HostingApi()
    public let deploy = DeployApi()
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

    public func get(for project: Project, with token: Token) throws -> [Application] {
        let endpoint = ApplicationApi.applicationsEndpoint + "?projectId=\(project.id.uuidString)"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request)
        return try [Application](node: response.json?["data"])
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
        public let environments = EnvironmentsApi()

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
        
        public func get(for application: Application, with token: Token) throws -> Hosting {
            let endpoint = applicationsEndpoint.finished(with: "/") + application.repo + "/hosting"
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
    public let applicationId: UUID
    public let branch: String
    public let id: UUID
    public let name: String
    public let running: Bool
    public let replicas: Int

    public init(node: Node) throws {
        // TODO: Full Model?
        applicationId = try node.get("application.id")
        branch = try node.get("defaultBranch")
        id = try node.get("id")
        name = try node.get("name")
        running = try node.get("running")
        replicas = try node.get("replicas")
    }
}

extension ApplicationApi.HostingApi {
    public final class EnvironmentsApi {
        public func create(
            for application: Application,
            name: String,
            branch: String,
            with token: Token
        ) throws -> Environment {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + application.repo + "/hosting/environments"
            let request = try Request(method: .post, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name)
            try json.set("defaultBranch", branch)
            request.json = json

            let response = try client.respond(to: request)
            return try Environment(node: response.json)
        }

        public func all(for application: Application, with token: Token) throws -> [Environment] {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + application.repo + "/hosting/environments"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try [Environment](node: response.json)
        }
    }
}

public enum DeployType: String {
    case clean, incremental
}

extension ApplicationApi {
    public final class DeployApi {
        //gitBranch (String) (Optional) What branch should be deployed code (String) (Required) Should be incremental or clean
        public func deploy(
            for app: Application,
            env: Environment,
            code: DeployType,
            with token: Token
        ) throws {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + app.repo
                + "/hosting/environments/"
                + env.name
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("code", code.rawValue)
            try json.set("replicas", 1)
            request.json = json
            
            let response = try client.respond(to: request)
            print("response: \(response)")
            print("")
        }

        public func scale(for app: Application, env: Environment, replicas: Int, with token: Token) throws {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + app.repo
                + "/hosting/environments/"
                + env.name
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("replicas", replicas)
            request.json = json
        }
    }
}
