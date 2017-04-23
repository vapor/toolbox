extension CloudAPIFactory {
    /// Creates a CloudAPI client authenticated
    /// with the global JWT token
    func makeAuthedClient(with console: ConsoleProtocol) throws -> CloudAPI {
        let cache = try TokenCache.global(with: console)
        let factory = try AccessTokenFactory(cache, self)
        return try makeClient(using: factory)
    }
}

import Foundation

final class TokenCache: CloudClients.TokenCache {
    init() throws {
        try FileManager.default.createVaporConfigFolderIfNecessary()
    }
    
    static func global(with console: ConsoleProtocol) throws -> TokenCache {
        let cache = try TokenCache()
        
        guard try cache.getRefreshToken() != nil else {
            console.info("No user currently logged in.")
            console.print("- Login: vapor cloud login")
            console.print("- Sign up: vapor cloud signup")
            throw "Login required"
        }
        
        return cache
    }
    
    var cache: JSON {
        get {
            do {
                let bytes = try DataFile.read(at: tokenPath)
                return try JSON(bytes: bytes)
            } catch {
                print("Could not load tokens: \(error)")
                return JSON()
            }
        }
        set {
            do {
                let bytes = try newValue.serialize()
                try DataFile.write(bytes, to: tokenPath)
            } catch {
                print("Could not save tokens: \(error)")
            }
        }
    }
    
    func getAccessToken() throws -> AccessToken? {
        guard let access = cache["access"]?.string else {
            return nil
        }
        return try AccessToken(string: access)
    }
    
    func getRefreshToken() throws -> RefreshToken? {
        guard let refresh = cache["refresh"]?.string else {
            return nil
        }
        return RefreshToken(string: refresh)
    }
    
    func setAccessToken(_ accessToken: AccessToken?) throws {
        try cache.set("access", accessToken?.makeString())
    }
    
    func setRefreshToken(_ refreshToken: RefreshToken?) throws {
        try cache.set("refresh", refreshToken?.makeString())
    }
}
