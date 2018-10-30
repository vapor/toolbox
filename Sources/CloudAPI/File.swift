import Vapor

extension String: Error {}

// TODO: Fix workaround
private let app: Application = {
    var config = Config.default()
    var env = try! Environment.detect()
    var services = Services.default()

    let app = try! Application(
        config: config,
        environment: env,
        services: services
    )

    return app
}()

internal func makeClient() throws -> Client {
    return try Request(using: app).make()
}

internal func makeWebSocketClient(url: URLRepresentable) throws -> Future<WebSocket> {
    return try makeClient().webSocket(url)
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

