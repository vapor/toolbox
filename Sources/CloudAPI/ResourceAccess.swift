import Vapor

struct ResourceAccess<T: Content> {
    let token: Token
    let baseUrl: String

    func view() throws -> T {
        let response = try send(.GET, to: baseUrl)
        return try response.become(T.self)
    }

    func view(id: String) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.GET, to: url)
        return try response.become(T.self)
    }

    func list(query: String? = nil) throws -> [T] {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = try send(.GET, to: url)
        return try response.become([T].self)
    }

    func create<U: Content>(_ content: U) throws -> T {
        let response = try send(.POST, to: baseUrl, with: content)
        return try response.become(T.self)
    }

    func update<U: Content>(id: String, with content: U) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PATCH, to: url, with: content)
        return try response.become(T.self)
    }

    func replace(id: String, with content: T) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PUT, to: url, with: content)
        return try response.become(T.self)
    }

    func delete(id: String) throws {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.DELETE, to: url)
        try response.validate()
    }
}

extension ResourceAccess {
    private func send<C: Content>(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        with content: C
        )  throws -> Future<Response> {
        return try send(method, to: url) { try $0.content.encode(content) }
    }

    private func send(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        beforeSend: (Request) throws -> () = { _ in }
        ) throws -> Future<Response> {
        // Headers
        var headers = token.headers
        headers.add(name: .contentType, value: "application/json")

        let client = try makeClient()
        let response = client.send(method, headers: headers, to: url, beforeSend: beforeSend)
        //        print(try! response.wait())
        return response
    }
}

extension Content {
    static func Access(with token: Token, baseUrl url: String) -> ResourceAccess<Self> {
        return ResourceAccess<Self>(token: token, baseUrl: url)
    }
}
