import ConsoleKit
import Foundation

extension String {
    public var trailingSlash: String {
        return finished(with: "/")
    }
    public func finished(with tail: String) -> String {
        guard hasSuffix(tail) else { return self + tail }
        return self
    }
    
    // Please note regarding the replacements for `NSPathUtilities` methods found below: The equivalent Foundation
    // methods are hidden from Swift for _GOOD REASON_. Please just use real URLs whenever possible.

    /// Convenience wrapper for `URL(fileURLWithPath:isDirectory:)`. This
    /// accessor should not be used if the path refers to a directory, but is
    /// more correct than `.asDirectoryURL` if the directory-ness is unknown.
    public var asFileURL: URL {
        return URL(fileURLWithPath: self, isDirectory: false)
    }
    
    /// Convenience wrapper for `URL(fileURLWithPath:isDirectory:)`. This
    /// accessor must not be used if the path refers to a file. If you don't
    /// know whether or not it refers to a directory, use `.asFileURL` instead.
    public var asDirectoryURL: URL {
        return URL(fileURLWithPath: self, isDirectory: true)
    }
    
    /// Convenience wrapper for `URL.pathComponents`
    public var pathComponents: [String] {
        return self.asFileURL.pathComponents
    }
    
    /// Convenience wrapper for `URL.lastPathComponent`
    public var lastPathComponent: String {
        return self.asFileURL.lastPathComponent
    }
    
    /// Convenience wrapper for repeated invocations of
    /// `URL.appendingPathComponent()` and `URL(fileURLWithPath:isDirectory:)`.
    public func appendingPathComponents(_ components: String...) -> String {
        return self.appendingPathComponents(components)
    }
    
    /// Convenience wrapper for repeated invocations of
    /// `URL.appendingPathComponent()` and `URL(fileURLWithPath:isDirectory:)`.
    public func appendingPathComponents(_ components: [String]) -> String {
        return components.reduce(self.asDirectoryURL) { $0.appendingPathComponent($1) }.relativePath
    }
    
    /// Convenience wrapper for repeated invocations of
    /// `URL.deletingLastPathComponent()`.
    public func deletingLastPathComponents(_ count: Int = 1) -> String {
        return (0..<count).reduce(self.asFileURL) { url, _ in url.deletingLastPathComponent() }.relativePath
    }
}

extension String: Error { }

extension Console {
    public func list(_ style: ConsoleStyle = .info, key: String, value: String) {
        self.output("\(key): ".consoleText(style) + value.consoleText())
    }
}

/// Represents the user's runtime version of Swift (major.minor).
struct RuntimeSwiftVersion {
    
    let major: Int
    let minor: Int
    
    /// Tries to detect the runtime version of Swift.
    ///
    /// It may not be possible to do it, that's why the initializer is failable.
    init?() {
        guard let rawVersion = Self.getRuntimeSwiftVersion() else { return nil }
        self.major = rawVersion[0]
        self.minor = rawVersion[1]
    }
    
    /// Tries to detect the runtime version of Swift.
    /// - Returns: An array which contains major and minor version numbers.
    static private func getRuntimeSwiftVersion() -> [Int]? {
        
        guard let rawVersionString = try? Process.shell.run(Process.shell.which("swift"), ["-version"])
        else { return nil }

        // Searching for a string like "Swift version 5.5"
        let regex = try! NSRegularExpression(pattern: "Swift[[:space:]]version[[:space:]]+[0-9]+.[0-9]+")
        guard let match = regex.firstMatch(in: rawVersionString, options: [], range: NSRange(location: 0, length: rawVersionString.utf8.count))
        else { return nil }
        
        let swiftVersionString = String(rawVersionString[Range(match.range, in: rawVersionString)!])
        
        let words = swiftVersionString.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard words.count == 3 else { return nil }
        
        // Splitting major and minor and assuring they are Int
        if words.last!.split(separator: ".").reduce(true, { $0 && (Int($1) != nil) }) {
            return words.last!.split(separator: ".").map { Int($0)! }
        } else {
            return nil
        }
    }
}

/// Checks if the *--enable-test-discovery* flag is needed.
/// This flag is deprecated in newer versions of Swift and it may cause a WARNING.
///
/// - Note: In case the version detection fails this function stays conservative and returns **true**.
func isEnableTestDiscoveryFlagNeeded() -> Bool {
    guard let version = RuntimeSwiftVersion() else { return true }
    
    return !(version.major > 5 || (version.major == 5 && version.minor >= 4)) //https://www.swift.org/blog/swift-5-4-released/
}
