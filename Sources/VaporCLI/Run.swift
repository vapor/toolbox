
struct Run: Command {
    static let id = "run"
    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        print("Running...")
        do {
            var parameters = args
            let name = args.valueFor(argument: "name") ?? "App"
            parameters.remove { $0.hasPrefix("--name") }

            let folder = args.contains("--release") ? "release" : "debug"
            parameters.remove("--release")

            // All remaining arguments are passed on to app
            let passthroughArgs = parameters.joined(separator: " ")
            // TODO: Check that file exists
            try shell.run(".build/\(folder)/\(name) \(passthroughArgs)")
        } catch Error.cancelled {
            // re-throw with updated message
            throw Error.cancelled("Run cancelled.")
        } catch {
            throw Error.failed("Could not run project.")
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

