import Console
import JSON
import Foundation

public final class Version: Command {
    public let id = "version"

    public let help: [String] = [
        "Displays Vapor CLI version"
    ]

    public let console: ConsoleProtocol
    public let version: String

    public init(console: ConsoleProtocol, version: String) {
        self.console = console
        self.version = version
    }

    public func run(arguments: [String]) throws {
        console.print("Vapor Toolbox: ", newLine: false)
        console.success("\(version)")

        guard verifySwiftProject() else { return }
        guard try isVaporProject(with: console) else {
            console.warning("No Vapor dependency detected, unable to log Framework Version")
            return
        }

        // If we have a vapor project, but checkouts
        // don't exist yet, we'll need to build
        let exists = try vaporCheckoutExists()
        if !exists {
            console.info("In order to find the Vapor Framework version of your project, it needs to be built at least once")
            guard console.confirm("Would you like to build now?") else {
                console.info("Vapor Framework version not available")
                return
            }

            try build()
        }

        let vapor = try vaporVersion()

        console.print("Vapor Framework: ", newLine: false)
        console.success("\(vapor)")
    }

    private func verifySwiftProject() -> Bool {
        do {
            let result = try console.backgroundExecute(program: "ls", arguments: ["./Package.swift"])
            return result.trim() == "./Package.swift"
        } catch {
            console.warning("No swift project detected, unable to log Framework Version")
            return false
        }
    }

    // To get the version properly, 
    // we need to ensure that the package has been built 
    // and dependencies resolved
    private func build() throws {
        let build = Build(console: console)
        try build.run(arguments: [])
    }

    private func vaporCheckoutExists() throws -> Bool {
        return try vaporCheckout() != nil
    }

    private func vaporVersion() throws -> String {
        guard let checkout = try vaporCheckout() else {
            throw ToolboxError.general("Unable to locate vapor dependency")
        }

        let gitDir = "--git-dir=./.build/checkouts/\(checkout)/.git"
        let workTree = "--work-tree=./.build/checkouts/\(checkout)"
        let version = try console.backgroundExecute(
            program: "git",
            arguments: [
                gitDir,
                workTree,
                "describe",
                "--exact-match",
                "--tags",
                "HEAD"
            ]
        )
        return version.trim()
    }

    private func vaporCheckout() throws -> String? {
        return try FileManager.default
            .contentsOfDirectory(atPath: "./.build/checkouts/")
            .lazy
            .filter { $0.hasPrefix("vapor.git") }
            .first
    }
}

internal func isVaporProject(with console: ConsoleProtocol) throws -> Bool {
    let dump = try console.backgroundExecute(program: "swift", arguments: ["package", "dump-package"])
    let json = try? JSON(bytes: dump.makeBytes())
    return json?["dependencies", "url"]?
        .array?
        .flatMap { $0.string }
        .contains("https://github.com/vapor/vapor.git")
        ?? false
}
