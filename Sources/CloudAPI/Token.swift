import Vapor

public struct Token: Content, Hashable {
    public let expiresAt: Date
    public let id: UUID
    public let userID: UUID
    public let token: String
}

extension Token {
    var headers: HTTPHeaders {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}

//extension Token {
//    var isValid: Bool {
//        return !isExpired
//    }
//    var isExpired: Bool {
//        return expiresAt < Date()
//    }
//}
//
//extension Token {
//    static func filePath() throws -> String {
//        let home = try Shell.homeDirectory()
//        return home.finished(with: "/") + ".vapor/token"
//    }
//
//    static func load() throws -> Token {
//        let path = try filePath()
//        let exists = FileManager
//            .default
//            .fileExists(atPath: path)
//        guard exists else { throw "not logged in, use 'vapor cloud login', and try again." }
//        let loaded = try FileManager.default.contents(atPath: path).flatMap {
//            try JSONDecoder().decode(Token.self, from: $0)
//        }
//        guard let token = loaded else {
//            throw "error, use 'vapor cloud login', and try again."
//        }
//        guard token.isValid else {
//            throw "expired credentials, use 'vapor cloud login', and try again."
//        }
//        return token
//    }
//
//    func save() throws {
//        let path = try Token.filePath()
//        let data = try JSONEncoder().encode(self)
//        let create = FileManager.default.createFile(
//            atPath: path, contents: data, attributes: nil
//        )
//        guard create else { throw "there was a problem svaing the token." }
//    }
//}
