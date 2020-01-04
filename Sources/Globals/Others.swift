import ConsoleKit

extension String {
    public var trailingSlash: String {
        return finished(with: "/")
    }
    public func finished(with tail: String) -> String {
        guard hasSuffix(tail) else { return self + tail }
        return self
    }
}

public protocol ToolboxGroup: CommandGroup {
    func fallback(using ctx: inout CommandContext) throws
}
extension ToolboxGroup {
    public var defaultCommand: AnyCommand? {
        return DefaultCommand { ctx in
            try self.fallback(using: &ctx)
        }
    }
}

fileprivate struct DefaultCommand: AnyCommand {
    let help: String = ""
    let runner: (inout CommandContext) throws -> Void

    func run(using ctx: inout CommandContext) throws {
        try runner(&ctx)
    }
}

