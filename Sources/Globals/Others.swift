import Vapor

extension CommandContext {
    public var done: EventLoopFuture<Void> {
        todo()
//        return eventLoop.makeSucceededFuture(Void())
//        return .done(on: eventLoop)
    }
}
