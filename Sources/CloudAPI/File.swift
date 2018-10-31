import Vapor

extension String: Error {}

public struct CloudApp: Content {
    public let updatedAt: Date
    public let name: String
    public let createdAt: Date
    public let namespace: String
    public let github: String?
    public let slug: String
    public let organizationID: UUID
    public let gitURL: String
    public let id: UUID
}

public struct Activity: Content {
    public let id: UUID
}

public struct CloudEnv: Content {
    public let defaultBranch: String
    public let applicationID: UUID
    public let createdAt: Date?
    public let id: UUID
    public let slug: String
    public let regionID: UUID
    public let updatedAt: Date?
    public let activity: Activity?
}

func makeApp() throws -> Application {
    let app = try Application(
        config: .default(),
        environment: .detect(),
        services: .default()
    )

    return app
}

func makeClient(on container: Container) -> Client {
    return FoundationClient.default(on: container)
}

public func makeWebSocketClient(url: URLRepresentable, on container: Container) -> Future<WebSocket> {
    return makeClient(on: container).webSocket(url)
}

extension Future where T == Response {
    internal func become<C: Content>(_ type: C.Type) -> Future<C> {
        return flatMap { response in
            let cloudError = try response.content.decode(ResponseError.self)
            return cloudError.mapIfError { cloudError in
                return ResponseError(error: false, reason: "")
            } .flatMap { cloudError in
                if cloudError.error { throw cloudError.reason }
                return try response.content.decode(C.self)
            }
        }
    }

    func validate() -> Future<Void> {
        return flatMap { response in
            let cloudError = try response.content.decode(ResponseError.self)
            return cloudError.mapIfError { cloudError in
                return ResponseError(error: false, reason: "")
            } .map { cloudError in
                if cloudError.error { throw cloudError.reason }
            }
        }
    }
}

//extension Future {
//    public func transformIfError<New>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping (Error) -> New) -> EventLoopFuture<New> {
//        return thenIfError(file: file, line: line) {
//            return Future<New>(eventLoop: self.eventLoop, result: callback($0), file: file, line: line)
//        }
//    }
//}

struct ResponseError: Content {
    let error: Bool
    let reason: String
}

extension Response {
    @discardableResult
    func throwIfError() throws -> Response {
        print(self)
//        let error = try content.decode(ResponseError.self)
//        error.w
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

