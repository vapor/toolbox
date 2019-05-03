import NIO
import Globals
import Foundation

//extension ByteBuffer {
//    public mutating func readData(length: Int) -> Data? {
//        return self.getData(at: self.readerIndex, length: length).map {
//            self.moveReaderIndex(forwardBy: length)
//            return $0
//        }
//    }
//}

//import NIOFoundationCompat
//extension HTTPClient.Response {
//    var toVapor: ClientResponse {
//        return ClientResponse(status: status, headers: headers, body: body)
//    }
//}

struct Web {
    static func send(_ req: HTTPClient.Request) throws -> HTTPClient.Response {
        let client = HTTPClient(eventLoopGroupProvider: .createNew)
        defer { try! client.syncShutdown() }
        let response = try client.execute(request: req).wait()
        // sometimes successful response is actually a cloud error
        if let err = try? response.become(ResponseError.self) {
            throw err
        }
        return response
    }
    
//    static func send(to url: String, method: HTTPMethod, headers: HTTPHeaders, body: Data)
//        throws -> HTTPClient.Response {
//            let client = HTTPClient(eventLoopGroupProvider: .createNew)
//            let req = try HTTPClient.Request(url: url, method: method, headers: headers, body: .data(body))
//            let resp = try client.execute(request: req).wait()
//            try client.syncShutdown()
//            return resp
//    }
//    
//    static func send(to url: String, method: HTTPMethod, headers: HTTPHeaders, body: ByteBuffer)
//        throws -> HTTPClient.Response {
//            var body = body
//            let data = body.readData(length: body.readableBytes)!
//            return try send(to: url, method: method, headers: headers, body: data)
//    }
//    
//    static func send<E: Encodable>(to url: String, method: HTTPMethod, headers: HTTPHeaders, body: E)
//        throws -> HTTPClient.Response {
//            let jsonEncoder = JSONEncoder()
//            let data = try jsonEncoder.encode(body)
//            return try send(to: url, method: method, headers: headers, body: data)
//    }
//    
//    static func send(_ req: ClientRequest) throws -> ClientResponse {
//        let req = try HTTPClient.Request(
//            url: req.url.absoluteString,
//            method: req.method,
//            headers: req.headers,
//            body: req.body.flatMap(HTTPClient.Body.byteBuffer)
//        )
//        let client = HTTPClient(eventLoopGroupProvider: .createNew)
//        let response = try client.execute(request: req).wait()
//        try client.syncShutdown()
//        return ClientResponse(status: response.status, headers: response.headers, body: response.body)
//    }
    
//    private static func _send(_ req: URLRequest) -> (Data?, URLResponse?, Error?) {
//        var resp: (Data?, URLResponse?, Error?)? = nil
//
//        let semaphore = DispatchSemaphore(value: 0)
//        let task = URLSession.shared.dataTask(with: req) { data, response, err in
//            resp = (data, response, err)
//            semaphore.signal()
//        }
//        task.resume()
//
//        let _ = semaphore.wait(timeout: .distantFuture)
//        guard let unwrap = resp else { fatalError("no result found") }
//        return unwrap
//    }
}

//extension ClientResponse {
//    func become<C: Content>(_ t: C.Type = C.self) throws -> C {
//        return try content.decode(C.self)
//    }
//}

import NIOHTTPClient

extension HTTPClient.Response {
    func become<C: Decodable>(_ t: C.Type = C.self) throws -> C {
        guard let body = body else { throw "missing body" }
        let data = body.makeData()
        let decoder = JSONDecoder()
        return try decoder.decode(C.self, from: data)
    }
}


//private extension URLRequest {
//    init(client request: ClientRequest) {
//        self.init(url: request.url)
//        self.httpMethod = request.method.string
//        if var body = request.body {
//            self.httpBody = body.readData(length: body.readableBytes)
//        }
//        request.headers.forEach { key, val in
//            self.addValue(val, forHTTPHeaderField: key.description)
//        }
//    }
//    
//    init(nioreq request: HTTPClient.Request) {
//        self.init(url: request.url)
//        self.httpMethod = request.method.string
//        self.httpBody = request.body?.raw
//        request.headers.forEach { key, val in
//            self.addValue(val, forHTTPHeaderField: key.description)
//        }
//    }
//}
//
//public func testNioHTTP() {
//    
//}

extension ByteBuffer {
    func makeData() -> Data {
        var copy = self
        let bytes = copy.readBytes(length: copy.readableBytes) ?? []
        return Data(bytes: bytes)
    }
}

extension HTTPClient.Body {
    var raw: Data {
        switch self {
        case .byteBuffer(var buffer):
            let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
            return Data(bytes: bytes)
        case .data(let data):
            return data
        case .string(let string):
            return Data(string.utf8)
        }
    }
    
    var buffer: ByteBuffer {
        var buf = ByteBufferAllocator().buffer(capacity: 0)
        buf.writeBytes(raw)
        return buf
    }
}

//private extension ClientResponse {
//    init(foundation: HTTPURLResponse, data: Data? = nil) {
//        self.init(status: .init(statusCode: foundation.statusCode))
//        if let data = data, !data.isEmpty {
//            var buffer = ByteBufferAllocator().buffer(capacity: data.count)
//            buffer.writeBytes(data)
//            self.body = buffer
//        }
//        for (key, value) in foundation.allHeaderFields {
//            self.headers.replaceOrAdd(name: "\(key)", value: "\(value)")
//        }
//    }
//}


private struct ResponseError: Resource, Error {
    let error: Bool
    let reason: String
}
