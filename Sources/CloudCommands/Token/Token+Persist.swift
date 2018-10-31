import Globals
import CloudAPI
import Foundation

extension Token {
    /// Save cloud Token
    func save() throws {
        let path = try Token.filePath()
        let data = try JSONEncoder().encode(self)
        let create = FileManager.default.createFile(
            atPath: path, contents: data, attributes: nil
        )
        guard create else { throw "there was a problem svaing the token." }
    }

    /// Load Cloud Token
    static func load() throws -> Token {
        let path = try filePath()
        let exists = FileManager
            .default
            .fileExists(atPath: path)
        guard exists else { throw "not logged in, use 'vapor cloud login', and try again." }
        let loaded = try FileManager.default.contents(atPath: path).flatMap {
            try JSONDecoder().decode(Token.self, from: $0)
        }
        guard let token = loaded else {
            throw "error, use 'vapor cloud login', and try again."
        }
        guard token.isValid else {
            throw "expired credentials, use 'vapor cloud login', and try again."
        }
        return token
    }

    private static func filePath() throws -> String {
        let home = try Shell.homeDirectory()
        return home.finished(with: "/") + ".vapor/token"
    }
}

extension Token {
    fileprivate var isValid: Bool {
        return !isExpired
    }
    fileprivate var isExpired: Bool {
        return expiresAt < Date()
    }
}
