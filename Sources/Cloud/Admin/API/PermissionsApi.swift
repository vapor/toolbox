import Foundation
import Vapor
import HTTP


public final class PermissionsApi<PermissionType: Permission, Model: Stitched> {
    public let base: String
    public let client: ClientFactoryProtocol

    public init(endpoint: String, client: ClientFactoryProtocol) {
        self.base = endpoint
        self.client = client
    }

    public func get(for model: Model, with token: Token) throws -> [PermissionType] {
        let id = try model.uuid().uuidString
        let endpoint = base.finished(with: "/") + id + "/permissions"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request)
        return try [PermissionType](node: response.json)
    }

    public func all(with token: Token) throws -> [PermissionType] {
        let endpoint = base.finished(with: "/") + "permissions"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request)
        return try [PermissionType](node: response.json)
    }

    public func set(_ permissions: [PermissionType], forUser user: UUID, in model: Model, with token: Token) throws -> [PermissionType] {
        let id = try model.uuid().uuidString
        let endpoint = base.finished(with: "/") + id + "/permissions"
        let request = try Request(method: .put, uri: endpoint)
        request.access = token

        var json = JSON([:])
        try json.set("userId", user)
        try json.set("permissions", permissions.map { $0.key })
        request.json = json

        let response = try client.respond(to: request)
        return try [PermissionType](node: response.json)
    }
}
