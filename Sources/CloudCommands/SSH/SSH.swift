import Globals
import ConsoleKit

public struct SSHGroup: ToolboxGroup {
    // empty sig
    public struct Signature: CommandSignature {
        public init() {}
    }
    
    public let commands: [String : AnyCommand] = [
        "add": SSHAdd(),
        "list": SSHList(),
        "delete": SSHDelete(),
    ]

    public let help: String = "interacts with ssh keys on vapor cloud."

    public init() {}

    public func fallback(using ctx: inout CommandContext) throws {
        ctx.console.info("interact with SSH Keys on vapor cloud.")
        ctx.console.output("use `vapor cloud ssh -h` to see commands.")
    }
}
