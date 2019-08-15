import ConsoleKit

public struct SSHGroup: CommandGroup {
    // empty sig
    public struct Signature: CommandSignature { }
    public let signature = Signature()
    
    public let commands: Commands = [
        "add": SSHAdd(),
        "list": SSHList(),
        "delete": SSHDelete(),
    ]

    public let help: String = "interacts with ssh keys on vapor cloud."

    public init() {}

    public func run(using ctx: CommandContext<SSHGroup>) throws {
        ctx.console.info("interact with SSH Keys on vapor cloud.")
        ctx.console.output("use `vapor cloud ssh -h` to see commands.")
    }
}
