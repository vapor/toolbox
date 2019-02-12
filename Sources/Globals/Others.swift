import Vapor

extension CommandContext {
    public var done: Future<Void> {
        return .done(on: container)
    }
}
