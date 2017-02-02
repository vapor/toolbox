import Console

public final class DockerBuild: Command {
    public let id = "build"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Builds the Docker application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        do {
            _ = try console.backgroundExecute(program: "which", arguments: ["docker"])
        } catch ConsoleError.backgroundExecute {
            console.info("Visit https://www.docker.com/products/docker-toolbox")
            throw ToolboxError.general("Docker not installed.")
        }

        do {
            let contents = try console.backgroundExecute(program: "ls", arguments: ["."])
            if !contents.contains("Dockerfile") {
                throw ToolboxError.general("No Dockerfile found")
            }
        } catch ConsoleError.backgroundExecute {
            throw ToolboxError.general("Could not check for Dockerfile")
        }

        let buildBar = console.loadingBar(title: "Building Docker image")
        buildBar.start()

        do {
            let imageName = DockerBuild.imageName(version: swiftVersion)
            _ = try console.backgroundExecute(program: "docker", arguments: ["build", "--rm", "-t", "vapor", "."])
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(_, let error, _) {
            buildBar.fail()
            throw ToolboxError.general("Docker build failed: \(error.string.trim())")
        }

        if console.confirm("Would you like to run the Docker image now?") {
            let build = DockerRun(console: console)
            try build.run(arguments: arguments)
        }
    }
}
