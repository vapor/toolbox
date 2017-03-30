public struct Token {
    public let access: String
    public let refresh: String
}

extension Token: Equatable {}
public func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.access == rhs.access
        && lhs.refresh == rhs.refresh
}
