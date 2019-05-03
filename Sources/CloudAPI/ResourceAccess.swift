import Globals
import Foundation
import NIOHTTP1
import NIOHTTPClient

public protocol Resource: Encodable, Decodable { }

public struct ResourceAccess<T: Resource> {
    public let token: Token
    public let baseUrl: String

    init(token: Token, baseUrl: String) {
        self.token = token
        self.baseUrl = baseUrl
    }

    public func view() throws -> T {
        let response = try send(.GET, to: baseUrl)
        return try response.become(T.self)
    }

    public func view(id: String) throws -> T {
        let url = self.baseUrl.trailingSlash + id
        let response = try send(.GET, to: url)
        return try response.become(T.self)
    }

    public func list(query: String? = nil) throws -> [T] {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = try send(.GET, to: url)
        return try response.become([T].self)
    }

    public func create<U: Encodable>(_ content: U) throws -> T {
        let response = try send(.POST, to: baseUrl, with: content)
        return try response.become(T.self)
    }

    public func update<U: Encodable>(id: String, with content: U) throws -> T {
        let url = self.baseUrl.trailingSlash + id
        let response = try send(.PATCH, to: url, with: content)
        return try response.become()
    }

    public func replace(id: String, with content: T) throws -> T {
        let url = self.baseUrl.trailingSlash + id
        let response = try send(.PUT, to: url, with: content)
        return try response.become()
    }

    public func delete(id: String) throws {
        let url = self.baseUrl.trailingSlash + id
        let _ = try send(.DELETE, to: url)
    }
}

extension ResourceAccess {
    fileprivate func send<C: Encodable>(
        _ method: HTTPMethod,
        to url: String,
        with content: C
    ) throws -> HTTPClient.Response {
        let encoder = JSONEncoder()
        let data = try encoder.encode(content)
        return try send(method, to: url, body: data)
    }

    private func send(
        _ method: HTTPMethod,
        to url: String,
        body: Data? = nil
    ) throws -> HTTPClient.Response {
        // Headers
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(token.key)")
        headers.add(name: "Content-Type", value: "application/json")

        let req = try HTTPClient.Request(
            url: url,
            method: method,
            headers: headers,
            body: body.flatMap(HTTPClient.Body.data)
        )
        return try Web.send(req)
    }
}

extension Resource {
    public static func Access(with token: Token, baseUrl url: String) -> ResourceAccess<Self> {
        return ResourceAccess<Self>(token: token, baseUrl: url)
    }
}
