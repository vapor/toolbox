import Console

public final class DockerBuild: Command {
    public let id = "build"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Builds the Docker application."
    ]

    public let console: Console

    public init(console: Console) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        do {
            _ = try console.subexecute("which docker")
        } catch ConsoleError.subexecute(_, _) {
            console.info("Visit https://www.docker.com/products/docker-toolbox")
            throw Error.general("Docker not installed.")
        }

        do {
            let contents = try console.subexecute("ls .")
            if !contents.contains("Dockerfile") {
                throw Error.general("No Dockerfile found")
            }
        } catch ConsoleError.subexecute(_) {
            throw Error.general("Could not check for Dockerfile")
        }

        let swiftVersion: String

        do {
            swiftVersion = try console.subexecute("cat .swift-version").trim()
        } catch {
            throw Error.general("Could not determine Swift version from .swift-version file.")
        }

        let buildBar = console.loadingBar(title: "Building Docker image")
        buildBar.start()

        do {
            let imageName = DockerBuild.imageName(version: swiftVersion)
            _ = try console.subexecute("docker build --rm -t \(imageName) --build-arg SWIFT_VERSION=\(swiftVersion) .")
            buildBar.finish()
        } catch ConsoleError.subexecute(_, let message) {
            buildBar.fail()
            throw Error.general("Docker build failed: \(message.trim())")
        }

        if console.confirm("Would you like to run the Docker image now?") {
            let build = DockerRun(console: console)
            try build.run(arguments: arguments)
        }
    }

    static func imageName(version: String) -> String {
        return "qutheory/swift:\(version)"
    }
}
