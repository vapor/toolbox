import Vapor

extension String: Error {}

func makeApp() throws -> Application {
    let app = try Application(
        config: .default(),
        environment: .detect(),
        services: .default()
    )

    return app
}

func makeClient(on container: Container) throws -> Client {
    return FoundationClient.default(on: container)
}

internal func makeWebSocketClient(url: URLRepresentable, on container: Container) throws -> Future<WebSocket> {
    return try makeClient(on: container).webSocket(url)
}

extension Future where T == Response {
    internal func become<C: Content>(_ type: C.Type) throws -> C {
        return try wait().throwIfError().content.decode(C.self).wait()
    }

    func validate() throws {
        let _ = try wait().throwIfError()
    }
}

struct ResponseError: Content {
    let error: Bool
    let reason: String
}

extension Response {
    func throwIfError() throws -> Response {
        if let error = try? content.decode(ResponseError.self).wait() {
            throw error.reason
        } else {
            return self
        }
    }
}

