
struct Build: Command {
    static let id = "build"
    static func execute(with args: [String], in shell: PosixSubsystem) throws {
        do {
            try shell.run("swift package fetch")
        } catch Error.cancelled {
            // re-throw with updated message
            throw Error.cancelled("Fetch cancelled")
        } catch {
            throw Error.failed("Could not fetch dependencies.")
        }

        var flags = args
        if args.contains("--release") {
            flags = flags.filter { $0 != "--release" }
            flags.append("-c release")
        }
        do {
            let buildFlags = flags.joined(separator: " ")
            try shell.run("swift build \(buildFlags)")
        } catch Error.cancelled {
            // re-throw with updated message
            throw Error.cancelled("Build cancelled")
        } catch {
            print()
            print("Need help getting your project to build?")
            print("Join our Slack where hundreds of contributors")
            print("are waiting to help: http://slack.qutheory.io")

            throw Error.failed("Could not build project.")
        }
    }
}

extension Build {
    static var help: [String] {
        return [
                   "build <module-name>",
                   "Builds source files and links Vapor libs.",
                   "Defaults to App/ folder structure."
        ]
    }
}

