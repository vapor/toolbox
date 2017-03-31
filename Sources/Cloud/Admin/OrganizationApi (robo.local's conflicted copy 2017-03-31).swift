import JSON
import Vapor
import Foundation
import HTTP

// admin-api-staging.vapor.cloud
// admin-api.vapor.cloud
// api.vapor.cloud/admin
// api-staging.vapor.cloud/admin

extension String: Error {}

extension AdminApi {
    public final class OrganizationApi {
        public let permissions = PermissionsApi<Organization>(endpoint: organizationsEndpoint, client: client)

        public func create(name: String, with token: Token) throws -> Organization {
            let request = try Request(method: .post, uri: organizationsEndpoint)
            request.access = token
            request.json = try JSON(node: ["name": name])

            let refresh = TokenRefreshMiddleware(token)
            let middleware = [refresh]
            let response = try client.respond(to: request, through: middleware)
            return try Organization(node: response.json)
        }

        public func all(with token: Token) throws -> [Organization] {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.access = token

            let refresh = TokenRefreshMiddleware(token)
            let middleware = [refresh]
            let response = try client.respond(to: request, through: middleware)
            // TODO: Should handle pagination
            return try [Organization](node: response.json?["data"])
        }

        public func get(id: UUID, with token: Token) throws -> Organization {
            return try get(id: id.uuidString, with: token)
        }

        public func get(id: String, with token: Token) throws -> Organization {
            let request = try Request(method: .get, uri: organizationsEndpoint)
            request.access = token
            request.json = try JSON(node: ["id": id])

            let refresh = TokenRefreshMiddleware(token)
            let middleware = [refresh]
            let response = try client.respond(to: request, through: middleware)

            // TODO: Discuss w/ Tanner, should this be returning 
            // an array for single item
            let org = response.json?["data"]?.array?.first
            return try Organization(node: org)
        }
    }
}

let tokenStorageKey = "cloud-client:token"
extension Request {
    internal var access: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.access)"
            storage[tokenStorageKey] = newValue
        }
    }
    internal var refresh: Token {
        get { fatalError() }
        set {
            headers["Authorization"] = "Bearer \(newValue.refresh)"
            storage[tokenStorageKey] = newValue
        }
    }
    
    internal var token: Token? {
        return storage[tokenStorageKey] as? Token
    }
}

public struct Color {
    public let name: String
    public let hex: String
    public init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }
}
