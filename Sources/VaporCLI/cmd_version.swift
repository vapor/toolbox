
struct Version: Command {
    static let id = "version"
    static func execute(with args: [String], in directory: String) {
        print("Vapor CLI version: \(version)")
    }
    static var help: [String] {
        return [
                   "display Vapor CLI version"
        ]
    }
}
