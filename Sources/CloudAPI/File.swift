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
    internal func become<C: Content>(_ type: C.Type) -> Future<C> {
        return flatMap { response in
            try response.throwIfError().content.decode(C.self)
        }
    }

    func validate() -> Future<Void> {
        return map {
            try $0.throwIfError()
        }
    }
}

struct ResponseError: Content {
    let error: Bool
    let reason: String
}

extension Response {
    @discardableResult
    func throwIfError() throws -> Response {
        print(self)
        let error = try content.decode(ResponseError.self)
        error.w
//        error.addAwaiter { result in
//            switch result {
//            // error means not response error
//            case .error(let er):
//
//            case .success(let responseError):
//            }
//        }

        if let error = try? content.decode(ResponseError.self).wait() {
            throw error.reason
        } else {
            return self
        }
    }
}

