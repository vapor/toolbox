extension ConsoleProtocol {
    func loadingBar<R>(title: String, ephemeral: Bool = false, _ closure: () throws -> (R)) rethrows -> R {
        let bar = loadingBar(title: title)
        let res = try bar.perform(closure)
        if ephemeral {
            clear(.line)
        }
        return res
    }
}
