import ConsoleKit
import Foundation
import Globals

extension Option where Value == Bool {
    static var dontOpenXcode: Option {
        return .init(name: "dont-open-xcode", short: "d", type: .flag, help: "use this flag to NOT open xcode after generation.")
    }
}

// Generates an Xcode project
struct XcodeCommand: Command {
    struct Signature: CommandSignature {
        let dontOpenXcode: Option = .dontOpenXcode
    }
    let signature = Signature()
    let help: String? = "generates xcode projects for spm packages."
    
    /// See `Command`.
    func run(using ctx: Context) throws {
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
        
        let openXcode = !ctx.flag(.dontOpenXcode)
        guard openXcode else { return }
        try Shell.bash("open *.xcodeproj")
    }
}

// Generates an Xcode project
struct BuildCommand: Command {
    struct Signature: CommandSignature {
    }
    let signature = Signature()
    let help: String? = "builds proj"
    
    /// See `Command`.
    func run(using ctx: Context) throws {
        ctx.console.output("building..")
        // execute
        let result = try Process.run("swift", args: ["build"]) { update in
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

