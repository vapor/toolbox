import Foundation
import Vapor
import HTTP

public protocol PermissionModel {
    var id: UUID { get }
}
extension Organization: PermissionModel {}
extension Project: PermissionModel {}

public final class PermissionsApi<Model: PermissionModel> {
    public let base: String
    public let client: ClientProtocol.Type

    public init(endpoint: String, client: ClientProtocol.Type) {
        self.base = endpoint
        self.client = client
    }

    public func get(for model: Model, with token: Token) throws -> [Permission] {
        let endpoint = base.finished(with: "/") + model.id.uuidString + "/permissions"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request, through: middleware)
        return try [Permission](node: response.json)
    }

    public func all(with token: Token) throws -> [Permission] {
        let endpoint = base.finished(with: "/") + "permissions"
        let request = try Request(method: .get, uri: endpoint)
        request.access = token

        let response = try client.respond(to: request, through: middleware)
        return try [Permission](node: response.json)
    }

    public func set(_ permissions: [String], for user: User, in model: Model, with token: Token) throws -> [Permission] {
        let endpoint = base.finished(with: "/") + model.id.uuidString + "/permissions"
        let request = try Request(method: .put, uri: endpoint)
        request.access = token

        var json = JSON([:])
        try json.set("userId", user.id.uuidString)
        try json.set("permissions", permissions)
        request.json = json

        let response = try client.respond(to: request, through: middleware)
        return try [Permission](node: response.json)
    }
}
