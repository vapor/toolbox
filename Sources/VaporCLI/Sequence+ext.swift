
extension Sequence where Iterator.Element == String {
    func valueFor(argument name: String) -> String? {
        for argument in self where argument.hasPrefix("--\(name)=") {
            return argument.characters.split(separator: "=").last.flatMap(String.init)
        }
        return nil
    }
}
