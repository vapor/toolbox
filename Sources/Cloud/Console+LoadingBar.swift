extension ConsoleProtocol {
    func loadingBar<R>(title: String, _ closure: () throws -> (R)) rethrows -> R {
        let bar = loadingBar(title: title)
        return try bar.perform(closure)
    }
}
