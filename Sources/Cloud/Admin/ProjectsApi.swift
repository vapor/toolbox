import Foundation
import JSON
import HTTP
import Vapor 

extension AdminApi {
    public final class ProjectsApi {
        public let permissions = PermissionsApi<Project>(endpoint: projectsEndpoint, client: client)

        public func create(
            name: String,
            color: String?,
            in org: Organization,
            with token: Token
        ) throws -> Project {
            let projectsUri = organizationsEndpoint.finished(with: "/") + org.id.uuidString + "/projects"
            let request = try Request(method: .post, uri: projectsUri)
            request.access = token

            var json = JSON()
            try json.set("name", name)
            try json.set("color", color)
            request.json = json

            let response = try client.respond(to: request)
            return try Project(node: response.json)
        }

        public func get(prefix: String, with token: Token) throws -> [Project] {
            // TODO: Size isn't active, 
            var endpoint = projectsEndpoint + "?size=25"
            if !prefix.isEmpty {
                endpoint += "&name=\(prefix)"
            }

            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            let projects = response.json?["data"]
            return try [Project](node: projects)
        }

        public func all(with token: Token) throws -> [Project] {
            return try get(prefix: "", with: token)
        }

        public func get(id: UUID, with token: Token) throws -> Project {
            return try get(id: id.uuidString, with: token)
        }

        public func get(id: String, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + id
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try Project(node: response.json)
        }

        public func all(for org: Organization, with token: Token) throws -> [Project] {
            // TODO: No endpoint for orgs yet, getting all and filtering manually,
            // update in future
            let projects = try all(with: token)
            return projects.filter { $0.organizationId == org.id }
        }

        public func update(_ project: Project, name: String?, color: String?, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + project.id.uuidString
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name ?? project.name)
            try json.set("color", color ?? project.color)
            request.json = json

            let response = try client.respond(to: request)
            return try Project(node: response.json)
        }

        public func colors(with token: Token) throws -> [Color] {
            let endpoint = projectsEndpoint.finished(with: "/") + "colors"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token
            
            let response = try client.respond(to: request)
            let colors = response.json?
                .object?
                .map { name, hex in
                    let hex = hex.string ?? ""
                    return Color(name: name, hex: hex)
                }
                as  [Color]?
            guard let unwrapped = colors else {
                throw "Bad response project colors: \(response)"
            }
            
            return unwrapped
        }
    }
}
