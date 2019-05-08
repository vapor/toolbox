import Globals
import CloudAPI
import Foundation

extension Token {
    /// Save cloud Token
    func save() throws {
        // ensure vapor directory already exists
        try makeVaporDirectoryIfNecessary()

        // create it
        let path = try Token.filePath()
        let data = try JSONEncoder().encode(self)
        let create = FileManager.default.createFile(
            atPath: path, contents: data, attributes: nil
        )
        guard create else { throw "there was a problem svaing the token." }
    }

    private func makeVaporDirectoryIfNecessary() throws {
        let vaporDirectory = try Shell.homeDirectory().trailingSlash + ".vapor"
        var isDirectory: ObjCBool = false
        let exists = FileManager.default
            .fileExists(atPath: vaporDirectory, isDirectory: &isDirectory)
        if exists && !isDirectory.boolValue {
            throw "found unexpected file at ~/.vapor"
        }
        guard !exists else { return }
        try FileManager.default.createDirectory(
            atPath: vaporDirectory,
            withIntermediateDirectories: false,
            attributes: nil
        )
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
        return home.trailingSlash + ".vapor/token"
    }
}

extension Token {
    fileprivate var isValid: Bool {
        return !isExpired
    }
    fileprivate var isExpired: Bool {
        return expiresAt < Date().timeIntervalSince1970
    }
}
