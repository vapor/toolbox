import Basic

// nothing here yet...

extension AbsolutePath: ExpressibleByStringLiteral {
    /// See `ExpressibleByStringLiteral`.
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

struct ToolboxError: Error {
    let reason: String
    init(_ reason: String) {
        self.reason = reason
    }
}
