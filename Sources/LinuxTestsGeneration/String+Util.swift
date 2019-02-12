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

/// workaround to swift syntax crashing on #file
func testsDirectory() -> String {
    let comps = #file.components(separatedBy: "/")
    var testsDirectory = ""
    for comp in comps {
        if comp == "Sources" {
            testsDirectory += "/Tests"
            break
        }
        testsDirectory += "/" + comp
    }
    return testsDirectory
}

