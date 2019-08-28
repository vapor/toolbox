import ConsoleKit
import AsyncWebSocketClient
import Foundation

struct Test: Command {
    struct Signature: CommandSignature {}
    let signature = Signature()
    let help = "quick tests. probably don't call this. you shouldn't see it."

    func run(using ctx: CommandContext, signature: Signature) throws {
        print("testing..")
    }
}
