import Console

public final class DockerRun: Command {
    public let id = "run"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Runs the Docker image created with the",
        "Docker build command."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        do {
            _ = try console.backgroundExecute(program: "which", arguments: ["docker"])
        } catch ConsoleError.backgroundExecute(_, _) {
            console.info("Visit https://www.docker.com/products/docker-toolbox")
            throw ToolboxError.general("Docker not installed.")
        }

        do {
            let contents = try console.backgroundExecute(program: "ls", arguments: ["."])
            if !contents.contains("Dockerfile") {
                throw ToolboxError.general("No Dockerfile found")
            }
        } catch ConsoleError.backgroundExecute(_) {
            throw ToolboxError.general("Could not check for Dockerfile")
        }

        let swiftVersion: String

        do {
            swiftVersion = try console.backgroundExecute(program: "cat", arguments: [".swift-version"]).trim()
        } catch {
            throw ToolboxError.general("Could not determine Swift version from .swift-version file.")
        }

        let imageName = DockerBuild.imageName(version: swiftVersion)
        
        console.info("Copy and run the following line:")
        console.print("docker run --rm -it -v $(PWD):/vapor -p 8080:8080 \(imageName)")
    }
}
