import Vapor

extension CommandContext {
    public var done: EventLoopFuture<Void> {
        return eventLoop.makeSucceededFuture(Void())
//        return .done(on: eventLoop)
    }
}
