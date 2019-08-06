import NIO
import Globals
import Foundation
import AsyncHTTPClient

struct Web {
    static func send(_ req: HTTPClient.Request) throws -> HTTPClient.Response {
        let client = HTTPClient(eventLoopGroupProvider: .createNew)
        defer { try! client.syncShutdown() }
        let response = try client.execute(request: req).wait()
        // sometimes successful response is actually a cloud error
        if let err = try? response.become(ResponseError.self) {
            throw err
        }
        return response.logged()
    }
}


let logResponses = false
extension HTTPClient.Response {
    fileprivate func logged() -> HTTPClient.Response {
        guard logResponses else { return self }
        print("Got response:\n\(self)\n\n")
        return self
    }
}

extension HTTPClient.Response {
    func become<C: Decodable>(_ t: C.Type = C.self) throws -> C {
        guard let data = body?.makeData() else { throw "missing body" }
        let decoder = JSONDecoder()
        return try decoder.decode(C.self, from: data)
    }
}

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

private struct ResponseError: Resource, Error {
    let error: Bool
    let reason: String
}
