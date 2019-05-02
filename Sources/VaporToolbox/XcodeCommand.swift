import Vapor
import Globals

extension Option where Value == Bool {
    static var hideXcode: Option {
        return .init(name: "hide-xcode", short: "h", type: .flag, help: "use this flag to NOT open xcode after generation.")
    }
}

// TODO: Xcode Additions
// automatically add xcconfig
// swift package generate-xcodeproj --xcconfig-overrides Sandbox.xcconfig
//
// automatically add environment variables to project file, more work,
// but would be nice
//
//
// Generates an Xcode project
struct XcodeCommand: Command {
    struct Signature: CommandSignature {
        let hideXcode: Option = .hideXcode
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
        
        let dontOpen = ctx.flag(.hideXcode)
        print("don't open: \(dontOpen)")
        guard !ctx.flag(.hideXcode) else { return }
        try Shell.bash("open *.xcodeproj")
    }
}
//
//struct _XcodeCommand: Command {
//    struct Signature: CommandSignature {}
//    let signature = Signature()
//    let help: String? = "generates xcode projects for spm packages."
//
//    /// See `Command`.
//    func run(using ctx: Context) throws {
//        ctx.console.output("generating xcodeproj..")
//
//        // execute
//        let process = try Process.run("swift", args: ["package"]) { update in
//            if let err = update.err {
//                ctx.console.output(err, style: .error, newLine: false)
//            }
//            if let out = update.out {
//                ctx.console.output(out, style: .plain, newLine: false)
//            }
//        }
//
//        if process == 0 {
//            ctx.console.output("generated xcodeproj.")
//            try Shell.bash("open *.xcodeproj")
//        } else {
//            ctx.console.output("failed to generate xcodeproj", style: .error, newLine: true)
//        }
//        print("ran xcode process: \(process)")
////        let generateProcess = Process.asyncExecute(
////            "swift",
////            ["package", "generate-xcodeproj"],
////            on: ctx.container
////        ) { output in
////            switch output {
////            case .stderr(let err):
////                let str = String(bytes: err, encoding: .utf8) ?? "error"
////                ctx.console.output("error:", style: .error, newLine: true)
////                ctx.console.output(str, style: .error, newLine: false)
////            case .stdout(let out):
////                let str = String(bytes: out, encoding: .utf8) ?? ""
////                ctx.console.output(str.consoleText(), newLine: false)
////            }
////        }
////
////        return generateProcess.map { val in
////            if val == 0 {
////                ctx.console.output(
////                    "success.",
////                    style: .info,
////                    newLine: true
////                )
////                try Shell.bash("open *.xcodeproj")
////            } else {
////                ctx.console.output(
////                    "failed to generate xcodeproj.",
////                    style: .error,
////                    newLine: true
////                )
////            }
////        }
//    }
//}
