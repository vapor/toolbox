import HTTP
import Vapor
import Foundation
import Node
import JSON

public let applicationApi = ApplicationApi()

extension Application: Stitched {}
extension Application: Equatable {}
public func == (lhs: Application, rhs: Application) -> Bool {
    return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.project.id == rhs.project.id
        && lhs.repoName == rhs.repoName
}

public final class ApplicationApi {
    // TODO: Make Internal
    internal static var base = "\(cloudURL)/application"
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
        try json.set("project.id", project.id)
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
        let id = try project.uuid().uuidString
        let endpoint = ApplicationApi.applicationsEndpoint + "?projectId=\(id)"
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

extension Hosting: Stitched {}
extension Hosting: Equatable {}
public func == (lhs: Hosting, rhs: Hosting) -> Bool {
    return lhs.id == rhs.id
    && lhs.gitURL == rhs.gitURL
    && lhs.application.id == rhs.application.id
}

import Console
extension ApplicationApi {
    public final class DatabaseApi {
        public func create(forRepo repo: String, envName env: String, with token: Token) throws {
            let endpoint = applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env
                + "/database"
            let req = try Request(method: .post, uri: endpoint)
            req.access = token

            // FIXME: temporarily hardcoding database id
            req.json = ["databaseServer": ["id": "A93DE7EC-9F64-4932-B86A-075CDD22AFB6"]]
            _ = try client.respond(to: req)
            /*
             Response
             - HTTP/1.1 200 OK
             - Headers:
             Date: Tue, 18 Apr 2017 11:39:08 GMT
             Content-Type: application/json; charset=utf-8
             Content-Length: 268
             Connection: keep-alive
             Server: nginx
             Strict-Transport-Security: max-age=15724800; includeSubDomains; preload
             - Body:
             {"databaseServer":"A93DE7EC-9F64-4932-B86A-075CDD22AFB6","environment":{"defaultBranch":"master","hosting":{"id":"6101D006-5604-4D80-961A-B4B1B717872C"},"id":"DE74E95C-9743-45D4-A9C7-DA150B3C151C","name":"production","replicas":0,"replicaSize":"free","running":false}}
             */
        }
    }
}

extension ApplicationApi {
    public final class HostingApi {
        let environments = EnvironmentsApi()

        // TODO: git expects ssh url, ie: git@github.com:vapor/vapor.git
        public func create(forRepo repo: String, git: String, with token: Token) throws -> Hosting {
            let endpoint = applicationsEndpoint.finished(with: "/") + repo + "/hosting"
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
            let endpoint = applicationsEndpoint.finished(with: "/") + application.repoName + "/hosting"
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

public typealias Environment = CloudModels.Environment

extension Environment: Stitched {}
extension Environment: Equatable {}
public func == (lhs: Environment, rhs: Environment) -> Bool {
    return lhs.hosting.id == rhs.hosting.id
        && lhs.defaultBranch == rhs.defaultBranch
        && lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.running == rhs.running
        && lhs.replicas == rhs.replicas
}

extension ApplicationApi {
    // TODO: ALl w/ forRepo instead of app

    public final class EnvironmentsApi {
        public let configs = ConfigsApi()
        public let database = DatabaseApi()

        public func create(
            forRepo repo: String,
            name: String,
            branch: String,
            replicaSize: ReplicaSize,
            with token: Token
        ) throws -> Environment {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/") + repo + "/hosting/environments"
            let request = try Request(method: .post, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name)
            try json.set("defaultBranch", branch)
            try json.set("replicaSize", replicaSize)
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
            return try all(forRepo: application.repoName, with: token)
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

public typealias Config = Configuration
extension Config: Stitched {}

extension ApplicationApi {
    public final class ConfigsApi {
        public func get(forRepo repo: String, envName env: String, with token: Token) throws -> [Config] {
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

        public func add(
            _ configs: [String: String],
            forRepo repo: String,
            envName env: String,
            with token: Token
        ) throws -> [Config] {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.finished(with: "/")
                + "configurations"

            let request = try Request(method: .patch, uri: endpoint)
            request.access = token
            request.json = try JSON(node: configs)

            let response = try client.respond(to: request)
            return try [Config](node: response.json)
        }

        public func replace(
            _ configs: [String: String],
            forRepo repo: String,
            envName env: String,
            with token: Token
            ) throws -> [Config] {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.finished(with: "/")
                + "configurations"
            let request = try Request(method: .put, uri: endpoint)
            request.access = token
            request.json = try JSON(node: configs)

            let response = try client.respond(to: request)
            return try [Config](node: response.json)
        }

        public func delete(
            keys: [String],
            forRepo repo: String,
            envName env: String,
            with token: Token
        ) throws {
            let endpoint = ApplicationApi.applicationsEndpoint.finished(with: "/")
                + repo
                + "/hosting/environments/"
                + env.finished(with: "/")
                + "configurations"
            let request = try Request(method: .delete, uri: endpoint)
            request.access = token
            request.json = try JSON(node: keys)

            _ = try client.respond(to: request)
        }
    }
}

public struct DeployInfo: NodeInitializable {
    public let hosting: Hosting
    public let defaultBranch: String
    public let deployment: Deployment
    public let id: UUID
    public let name: String
    public let replicas: Int
    public let running: Bool

    public init(node: Node) throws {
        hosting = try node.get("hosting")
        defaultBranch = try node.get("defaultBranch")
        deployment = try node.get("deployment")
        id = try node.get("id")
        name = try node.get("name")
        replicas = try node.get("replicas")
        running = try node.get("running")
    }
}

extension Deployment: Stitched {}
extension Deployment.Method {
    public var isScaleDeploy: Bool {
        guard case .scale = self else { return false }
        return true
    }
    public var isCodeDeploy: Bool {
        guard case .code = self else { return false }
        return true
    }
}

public typealias BuildType = Deployment.CodeMethod
extension BuildType {
    static let all: [BuildType] = [.incremental, .update, .clean]
    public var rawValue: String {
        switch self {
        case .clean:
            return "clean"
        case .incremental:
            return "incremental"
        case .update:
            return "update"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "clean":
            self = .clean
        case "incremental":
            self = .incremental
        case "update":
            self = .update
        default:
            return nil
        }
    }
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
            ) throws -> DeployInfo {
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

            return try DeployInfo(node: response.json)
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
