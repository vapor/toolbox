import Foundation
import JSON
import HTTP
import Vapor 

extension AdminApi {
    public final class ProjectsApi {
        public let permissions = PermissionsApi<Project>(endpoint: projectsEndpoint, client: client)

        public func create(name: String, color: String?, organizationId: String, with token: Token) throws -> Project {
            let projectsUri = organizationsEndpoint.finished(with: "/") + organizationId + "/projects"
            let request = try Request(method: .post, uri: projectsUri)
            request.access = token

            var json = JSON()
            try json.set("name", name)
            if let color = color {
                try json.set("color", color)
            }
            request.json = json

            let response = try client.respond(to: request, through: middleware)
            return try Project(node: response.json)
        }

        public func get(query: String, with token: Token) throws -> [Project] {
            let endpoint = projectsEndpoint + "?name=\(query)"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request, through: middleware)
            let projects = response.json?["data"]
            return try [Project](node: projects)
        }

        public func get(id: UUID, with token: Token) throws -> Project {
            return try get(id: id.uuidString, with: token)
        }

        public func get(id: String, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + id
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request, through: middleware)
            return try Project(node: response.json)
        }

        public func update(_ project: Project, name: String?, color: String?, with token: Token) throws -> Project {
            let endpoint = projectsEndpoint.finished(with: "/") + project.id.uuidString
            let request = try Request(method: .patch, uri: endpoint)
            request.access = token

            var json = JSON([:])
            try json.set("name", name ?? project.name)
            try json.set("color", color ?? project.color)
            request.json = json

            let response = try client.respond(to: request, through: middleware)
            return try Project(node: response.json)
        }

        public func colors(with token: Token) throws -> [Color] {
            let endpoint = projectsEndpoint.finished(with: "/") + "colors"
            let request = try Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request, through: middleware)
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
