import Vapor
import Globals

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


private struct ResponseError: Content {
    let error: Bool
    let reason: String
}
