
struct Run: Command {
    static let id = "run"
    static func execute(with args: [String], in directory: String) {
        print("Running...")
        do {
            var parameters = args
            let name = args.valueFor(argument: "name") ?? "App"
            parameters.remove { $0.hasPrefix("--name") }

            let folder = args.contains("--release") ? "release" : "debug"
            parameters.remove("--release")

            // All remaining arguments are passed on to app
            let passthroughArgs = args.joined(separator: " ")
            // TODO: Check that file exists
            try run(".build/\(folder)/\(name) \(passthroughArgs)")
        } catch Error.cancelled {
            fail("Run cancelled.")
        } catch {
            fail("Could not run project.")
        }
    }
}

extension Run {
    static var help: [String] {
        return [
                   "runs executable built by vapor build.",
                   "use --release for release configuration."
        ]
    }
}

