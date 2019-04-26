import Vapor
import Globals

public struct ResourceAccess<T: Content> {
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
        let url = self.baseUrl.trailSlash + id
        let response = try send(.GET, to: url)
        return try response.become(T.self)
    }

    public func list(query: String? = nil) throws -> [T] {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = try send(.GET, to: url)
        return try response.become([T].self)
    }

    public func create<U: Content>(_ content: U) throws -> T {
        let response = try send(.POST, to: baseUrl, with: content)
        return try response.become(T.self)
    }

    public func update<U: Content>(id: String, with content: U) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PATCH, to: url, with: content)
        return try response.become()
    }

    public func replace(id: String, with content: T) throws -> T {
        let url = self.baseUrl.trailSlash + id
        let response = try send(.PUT, to: url, with: content)
        return try response.become()
    }

    public func delete(id: String) throws {
        let url = self.baseUrl.trailSlash + id
        let _ = try send(.DELETE, to: url)
    }
}

extension ResourceAccess {
    fileprivate func send<C: Content>(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        with content: C
    ) throws -> ClientResponse {
        return try send(method, to: url) {
            try $0.content.encode(content)
        }
    }

    private func send(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        beforeSend: (inout ClientRequest) throws -> () = { _ in }
    ) throws -> ClientResponse {
        // Headers
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(token.key)")
        headers.add(name: .contentType, value: "application/json")

        var req = ClientRequest(method: method, url: url.convertToURL()!, headers: headers, body: nil)
        try beforeSend(&req)

        return try Web.send(req).logged()
    }
}

extension ClientRequest {
    init<C: Content>(method: HTTPMethod, url rep: URLRepresentable, headers: HTTPHeaders = [:], body: C) throws {
        guard let url = rep.convertToURL() else { throw "unable to convert \(rep) to url" }
        var req = ClientRequest(method: method, url: url, headers: headers, body: nil)
        try req.content.encode(body)
        self = req
    }
}

extension Content {
    public static func Access(with token: Token, baseUrl url: String) -> ResourceAccess<Self> {
        return ResourceAccess<Self>(token: token, baseUrl: url)
    }
}


let logResponses = true
extension ClientResponse {
    func logged() -> ClientResponse {
        guard logResponses else { return self }
        print("Got response:\n\(self)\n\n")
        return self
    }
}
