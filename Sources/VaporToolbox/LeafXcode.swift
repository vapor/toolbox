import Vapor
import Globals
import Leaf


let vaporDependency = NewProjectConfig.Dependency(
    gitUrl: "https://github.com/vapor/vapor.git",
    version: "3.0.0",
    includes: ["Vapor"],
    comment: "💧 A server-side Swift web framework."
)

let leafDependency = NewProjectConfig.Dependency(
    gitUrl: "https://github.com/vapor/leaf.git",
    version: "3.0.0",
    includes: ["Leaf"],
    comment: "a templating engine"
)

struct NewProjectConfig: Content {
    struct Dependency: Content {
        let gitUrl: String
        let version: String
        let comment: String?

        // the names to include as dependencies, for example ["FluentSQLite"]
        // usually one name, but possible to have dependency w/ multiple
        // libraries
        let includes: [String]

        private(set) var package: String

        init(gitUrl: String, version: String, includes: [String], comment: String? = nil) {
            self.gitUrl = gitUrl
            self.version = version
            self.includes = includes
            self.comment = comment

            self.package = ".package(url: " + gitUrl + ", from: " + version + ")"
        }
//        func _package() -> String {
//            var generated = ""
//            if let comment = comment {
//                generated += "// " + comment + "\n"
//            }
//            generated += ".package(url: " + gitUrl + ", from: " + version + "),"
//            return generated
//        }
    }

    var swiftVersion = "4.1"
    var dependencies: [Dependency] = [vaporDependency, leafDependency]
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
struct LeafXcodeCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["generates xcode projects for spm packages."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        return try testPackageSwiftLoad(ctx: ctx)
        ctx.console.output("loading leaf file")
        let file = try Shell.readFile(path: "~/Desktop/test-leaf-file.swift")

        let config = LeafConfig(tags: .default(), viewsDir: "./", shouldCache: false)
        let renderer = LeafRenderer(config: config, using: ctx.container)
        let data = Data(bytes: file.utf8)
        let rendered = renderer.render(template: data, ["name": "context"])
        return rendered.map { view in
            print(view)
            let str = String(bytes: view.data, encoding: .utf8)
            print(str)
            ctx.console.output("got file:")
            ctx.console.output(file.consoleText())
        }
//        return .done(on: ctx.container)

//        ctx.console.output("generating xcodeproj...")
//        let generateProcess = Process.asyncExecute(
//            "swift",
//            ["package", "generate-xcodeproj"],
//            on: ctx.container
//        ) { output in
//            switch output {
//            case .stderr(let err):
//                let str = String(bytes: err, encoding: .utf8) ?? "error"
//                ctx.console.output("error:", style: .error, newLine: true)
//                ctx.console.output(str, style: .error, newLine: false)
//            case .stdout(let out):
//                let str = String(bytes: out, encoding: .utf8) ?? ""
//                ctx.console.output(str.consoleText(), newLine: false)
//            }
//        }
//
//        return generateProcess.map { val in
//            if val == 0 {
//                ctx.console.output(
//                    "success.",
//                    style: .info,
//                    newLine: true
//                )
//                try Shell.bash("open *.xcodeproj")
//            } else {
//                ctx.console.output(
//                    "failed to generate xcodeproj.",
//                    style: .error,
//                    newLine: true
//                )
//            }
//        }
    }
}

func testPackageSwiftLoad(ctx: CommandContext) throws -> Future<Void> {
    let file = try Shell.readFile(path: "~/Desktop/delete-me/Package.swift")

    let config = LeafConfig(tags: .default(), viewsDir: "./", shouldCache: false)
    let renderer = LeafRenderer(config: config, using: ctx.container)
    let data = Data(bytes: file.utf8)
    let newProjectConfig = NewProjectConfig()
    let rendered = renderer.render(template: data, newProjectConfig)
//    let rendered = renderer.render(template: data, ["packages": ["context", "foo", "bar"]])
    return rendered.map { view in
        print(view)
        let str = String(bytes: view.data, encoding: .utf8)
        print(str!)
        ctx.console.output("got file:")
        ctx.console.output(file.consoleText())
    }
}
