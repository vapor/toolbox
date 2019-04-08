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

extension EventLoopFuture where Value == HTTPResponse {

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
        todo()
//        return validate().flatMap { try $0.content.decode(C.self) }
    }

    /// Use this to parse out error responses
    /// they return 200, but contents are an error
    /// otherwise error is decoding and unclear
    ///
    /// this logic is a bit unclear,
    /// but I don't have a better way to map where
    /// contents might be A or B and need to move on
    /// will think about and revisit
    internal func validate() -> EventLoopFuture<HTTPResponse> {
        todo()
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
