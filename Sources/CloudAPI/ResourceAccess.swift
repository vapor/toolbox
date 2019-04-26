import Vapor
import Globals

public struct ResourceAccess<T: Content> {
    public let token: Token
    public let baseUrl: String
    public let container: Container

    init(token: Token, baseUrl: String, on container: Container) {
        self.token = token
        self.baseUrl = baseUrl
        self.container = container
    }

    public func view() -> EventLoopFuture<T> {
        let response = send(.GET, to: baseUrl)
        return response.become(T.self)
    }

    public func view(id: String) -> EventLoopFuture<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.GET, to: url)
        return response.become(T.self)
    }

    public func list(query: String? = nil) -> EventLoopFuture<[T]> {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = send(.GET, to: url)
        return response.become([T].self)
    }

    public func create<U: Content>(_ content: U) -> EventLoopFuture<T> {
        let response = send(.POST, to: baseUrl, with: content)
        return response.become(T.self)
    }

    public func update<U: Content>(id: String, with content: U) -> EventLoopFuture<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.PATCH, to: url, with: content)
        return response.become(T.self)
    }

    public func replace(id: String, with content: T) -> EventLoopFuture<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.PUT, to: url, with: content)
        return response.become(T.self)
    }

    public func delete(id: String) -> EventLoopFuture<Void> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.DELETE, to: url)
        return response.validate().void()
    }
}

extension ResourceAccess {
    private func send<C: Content>(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        with content: C
    ) -> EventLoopFuture<ClientResponse> {
        return send(method, to: url) { try $0.content.encode(content) }
    }

    private func send(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        beforeSend: (inout ClientRequest) throws -> () = { _ in }
    ) -> EventLoopFuture<ClientResponse> {
        // Headers
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(token.key)")
        headers.add(name: .contentType, value: "application/json")

        let client: FoundationClient = { todo() }() // = FoundationClient.default(on: container)
        var req = ClientRequest(method: method, url: url.convertToURL()!, headers: headers, body: nil)
        try! beforeSend(&req)
        return client.send(req).map(logResponse)
    }
}

extension Content {
    public static func Access(with token: Token, baseUrl url: String, on container: Container) -> ResourceAccess<Self> {
        return ResourceAccess<Self>(token: token, baseUrl: url, on: container)
    }
}


let logResponses = true
func logResponse(_ resp: ClientResponse) -> ClientResponse {
    guard logResponses else { return resp }
    print("Got response:\n\(resp)\n\n")
    return resp
}
