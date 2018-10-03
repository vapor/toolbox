extension String: Error {}
extension String {
    /// Ensures a string has a trailing suffix w/o duplicating
    ///
    ///     "hello.jpg".finished(with: ".jpg") // hello.jpg
    ///     "hello".finished(with: ".jpg") // hello.jpg
    ///
    func finished(with end: String) -> String {
        guard !self.hasSuffix(end) else { return self }
        return self + end
    }
}
