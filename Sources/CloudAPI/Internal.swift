import Vapor
import Globals

//let group = MultiThreadedEventLoopGroup(numberOfThreads: { todo() }())

//internal func makeClient() -> Client {
//    let next = group.next()
//    return FoundationClient(.shared, on: next)
//}

struct Web {
    static func send(_ req: ClientRequest) throws -> ClientResponse {
        let (data, resp, err) = _send(.init(client: req))
        if let err = err { throw err }
        guard let httpResp = resp as? HTTPURLResponse else { fatalError("URLResponse was not a HTTPURLResponse") }
        let response = ClientResponse(foundation: httpResp, data: data)
        
        // check if we have a successful httpresponse that contains a cloudresponse error
        if let cloudError = try? response.content.decode(ResponseError.self), cloudError.error {
            throw cloudError.reason
        }
        return response
    }
    
    private static func _send(_ req: URLRequest) -> (Data?, URLResponse?, Error?) {
        var resp: (Data?, URLResponse?, Error?)? = nil
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: req) { data, response, err in
            resp = (data, response, err)
            semaphore.signal()
        }
        task.resume()
        
        let _ = semaphore.wait(timeout: .distantFuture)
        guard let unwrap = resp else { fatalError("no result found") }
        return unwrap
    }
}

extension ClientResponse {
    func become<C: Content>(_ t: C.Type = C.self) throws -> C {
        return try content.decode(C.self)
    }
}


private extension URLRequest {
    init(client request: ClientRequest) {
        self.init(url: request.url)
        self.httpMethod = request.method.string
        if var body = request.body {
            self.httpBody = body.readData(length: body.readableBytes)
        }
        request.headers.forEach { key, val in
            self.addValue(val, forHTTPHeaderField: key.description)
        }
    }
}

private extension ClientResponse {
    init(foundation: HTTPURLResponse, data: Data? = nil) {
        self.init(status: .init(statusCode: foundation.statusCode))
        if let data = data, !data.isEmpty {
            var buffer = ByteBufferAllocator().buffer(capacity: data.count)
            buffer.writeBytes(data)
            self.body = buffer
        }
        for (key, value) in foundation.allHeaderFields {
            self.headers.replaceOrAdd(name: "\(key)", value: "\(value)")
        }
    }
}

internal func makeWebSocketClient(url: URLRepresentable, on container: Container) -> EventLoopFuture<WebSocket> {
    todo()
//    return makeClient(on: container).webSocket(url)
}

private struct ResponseError: Content {
    let error: Bool
    let reason: String
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
    }
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
