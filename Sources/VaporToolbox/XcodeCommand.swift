import ConsoleKit
import Foundation
import Globals

// Generates an Xcode project
struct XcodeCommand: Command {
    struct Signature: CommandSignature {
        @Flag(name: "suppress-xcode", short: "s", help: "use this flat to suppress xcode from opening after generation.")
        var supressXcode: Bool
    }

    let help = "generates xcode projects for spm packages."
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("generating xcodeproj..")
        
        // execute
        let result = try Process.run("swift", args: ["package", "generate-xcodeproj"]) { update in
            if let err = update.err {
                ctx.console.output(err, style: .error, newLine: false)
            }
            if let out = update.out {
                ctx.console.output(out, style: .plain, newLine: false)
            }
        }
        
        guard result == 0 else { throw "failed to generate xcodeproj." }
        ctx.console.output("generated xcodeproj.")
        
        let openXcode = !signature.supressXcode
        guard openXcode else { return }
        try Shell.bash("open *.xcodeproj")
    }
}

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {}
    
    let help = "builds proj"
    
    /// See `Command`.
    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("building..")
        // execute
        print("args: \(ctx.input.arguments.joined(separator: ", "))")
        let result = try Process.run("swift", args: ["build"] + ctx.input.arguments) { update in
            if let err = update.err {
                ctx.console.output(err, style: .error, newLine: false)
            }
            if let out = update.out {
                ctx.console.output(out, style: .plain, newLine: false)
            }
        }
        
        guard result == 0 else { throw "failed to build." }
        ctx.console.output("built.")
    }
}

