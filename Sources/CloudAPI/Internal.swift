import Vapor
import Globals

internal func makeClient(on container: Container) -> Client {
    todo()
//    return FoundationClient.default(on: container)
}

internal func makeWebSocketClient(url: URLRepresentable, on container: Container) -> EventLoopFuture<WebSocket> {
    todo()
//    return makeClient(on: container).webSocket(url)
}

private struct ResponseError: Content {
    let error: Bool
    let reason: String
}

extension EventLoopFuture {
    public func _flatMap<NewValue>(file: StaticString = #file, line: UInt = #line, _ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>) -> EventLoopFuture<NewValue> {
        let wrapped: (Value) -> EventLoopFuture<NewValue> = { [unowned self] in
            do {
                return try callback($0)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
        return flatMap(wrapped)
    }
}

extension EventLoopFuture where Value == ClientResponse {

    /// Clear the response
    /// Should ALWAYS (until you don't want to) call `validate()`
    /// first
    internal func void() -> EventLoopFuture<Void> {
        return map { _ in }
    }

    /// Use this to parse out error responses
    /// they return 200, but contents are an error
    /// otherwise error is decoding and unclear
    ///
    /// this logic is a bit unclear,
    /// but I don't have a better way to map where
    /// contents might be A or B and need to move on
    /// will think about and revisit
    internal func become<C: Content>(_ type: C.Type) -> EventLoopFuture<C> {
        return validate().flatMapThrowing { try $0.content.decode(C.self) }
    }

    /// Use this to parse out error responses
    /// they return 200, but contents are an error
    /// otherwise error is decoding and unclear
    ///
    /// this logic is a bit unclear,
    /// but I don't have a better way to map where
    /// contents might be A or B and need to move on
    /// will think about and revisit
    internal func validate() -> EventLoopFuture<ClientResponse> {
        return flatMapThrowing { response in
            // Check if ErrorResponse (they return a successful 200, but are actually errors)
            if let cloudError = try? response.content.decode(ResponseError.self), cloudError.error {
                throw cloudError.reason
            }
            // if UNABLE to map ResponseError
            // then the success response should be our object
            // pass along response for subsequent testing
            return response
        }

//        return flatMap { response in
//            // Check if ErrorResponse (returns 200, but is error)
//            let cloudError = try response.content.decode(ResponseError.self)
//            return cloudError.mapIfError { cloudError in
//                // if UNABLE to map ResponseError
//                // then it is our object
//                return ResponseError(error: false, reason: "")
//            } .map { cloudError in
//                if cloudError.error { throw cloudError.reason }
//                return response
//            }
//        }
    }
}
