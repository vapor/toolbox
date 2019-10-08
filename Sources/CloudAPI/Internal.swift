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

extension JSONDecoder {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer()
            if let timestamp = try? value.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            } else if let iso8601 = try? value.decode(String.self) {
                if #available(OSX 10.12, *) {
                    if let date = ISO8601DateFormatter().date(from: iso8601) {
                        return date
                    } else {
                        throw "unable to convert date string '\(iso8601)'"
                    }
                } else {
                    fatalError("unsupported version")
                }
            }
            throw "unexpected type for expiresAt \(decoder)"
        }
        return decoder
    }
}

extension HTTPClient.Response {
    func become<C: Decodable>(_ t: C.Type = C.self) throws -> C {
        guard let data = body?.makeData() else { throw "missing body" }
        return try JSONDecoder.decoder.decode(C.self, from: data)
    }
}

extension ByteBuffer {
    func makeData() -> Data {
        var copy = self
        let bytes = copy.readBytes(length: copy.readableBytes) ?? []
        return Data(bytes)
    }
}

private struct ResponseError: Resource, Error {
    let error: Bool
    let reason: String
}
