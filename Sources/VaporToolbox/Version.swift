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

        guard projectInfo.isSwiftProject() else { return }
        guard projectInfo.isVaporProject() else {
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

        let vapor = try projectInfo.vaporVersion()

        console.print("Vapor Framework: ", newLine: false)
        console.success("\(vapor)")
    }

    // To get the version properly, 
    // we need to ensure that the package has been built 
    // and dependencies resolved
    private func build() throws {
        let build = Build(console: console)
        try build.run(arguments: [])
    }

    private func vaporCheckoutExists() throws -> Bool {
        return try projectInfo.vaporCheckout() != nil
    }
}
