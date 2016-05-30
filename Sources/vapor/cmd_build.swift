
struct Build: Command {
    static let id = "build"
    static func execute(with args: [String], in directory: String) {
        do {
            try run("swift build --fetch")
        } catch Error.cancelled {
            fail("Fetch cancelled")
        } catch {
            fail("Could not fetch dependencies.")
        }

        do {
            try run("rm -rf Packages/Vapor-*/Sources/Development")
            try run("rm -rf Packages/Vapor-*/Sources/Performance")
            try run("rm -rf Packages/Vapor-*/Sources/Generator")
        } catch {
            print("Failed to remove extra schemes")
        }

        var flags = args
        if args.contains("--release") {
            flags = flags.filter { $0 != "--release" }
            flags.append("-c release")
        }
        do {
            let buildFlags = flags.joined(separator: " ")
            try run("swift build \(buildFlags)")
        } catch Error.cancelled {
            fail("Build cancelled.")
        } catch {
            print()
            print("Make sure you are running Apple Swift version 3.0.")
            print("Vapor only supports the latest snapshot.")
            print("Run swift --version to check your version.")

            fail("Could not build project.")
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

