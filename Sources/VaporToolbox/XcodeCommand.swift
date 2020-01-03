import ConsoleKit
import Foundation
import Globals

// Generates an Xcode project
struct XcodeCommand: Command {
    struct Signature: CommandSignature { }

    let help = "Opens a Vapor project in Xcode."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        try Shell.bash("open Package.swift")
    }
}
