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
