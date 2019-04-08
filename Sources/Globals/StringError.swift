extension String: Error {}

extension String {
    public func finished(with suffix: String) -> String {
        if self.hasSuffix(suffix) { return self }
        else { return self + suffix }
    }
}
