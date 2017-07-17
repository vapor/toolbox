import JSON
import Vapor
import Foundation
import HTTP

extension String: Error {}

extension AdminApi {
    public final class OrganizationApi {
        public let permissions = PermissionsApi<OrganizationPermission, Organization>(
            endpoint: organizationsEndpoint,
            client: client
        )

        public func create(name: String, with token: Token) throws -> Organization {
            let request = Request(method: .post, uri: organizationsEndpoint)
            request.access = token
            request.json = try JSON(node: ["name": name])

            let response = try client.respond(to: request)
            return try Organization(node: response.json)
        }

        public func all(with token: Token) throws -> [Organization] {
            let request = Request(method: .get, uri: organizationsEndpoint)
            request.access = token

            let response = try client.respond(to: request)
            
            // TODO: Should handle pagination
            return try [Organization](node: response.json?["data"])
        }

        public func get(id: Identifier?, with token: Token) throws -> Organization {
            let uuid = try id.uuid()
            return try get(id: uuid, with: token)
        }

        public func get(id: UUID, with token: Token) throws -> Organization {
            return try get(id: id.uuidString, with: token)
        }

        public func get(id: String, with token: Token) throws -> Organization {
            let endpoint = organizationsEndpoint.finished(with: "/") + id
            let request = Request(method: .get, uri: endpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try Organization(node: response.json)
        }
    }
}

public struct Color: NodeInitializable {
    public let name: String
    public let hex: String

    public init(node: Node) throws {
        name = try node.get("name")
        hex = try node.get("hex")
    }
}
