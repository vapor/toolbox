import ConsoleKit

extension String {
    public var trailingSlash: String {
        return finished(with: "/")
    }
    public func finished(with tail: String) -> String {
        guard hasSuffix(tail) else { return self + tail }
        return self
    }
}

extension String: Error { }

extension Console {
    public func list(_ style: ConsoleStyle = .info, key: String, value: String) {
        self.output("\(key): ".consoleText(style) + value.consoleText())
    }
}
