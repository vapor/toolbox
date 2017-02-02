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
        } catch ConsoleError.backgroundExecute {
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
        
        console.info("Copy and run the following line:")
        console.print("docker run --rm -it -v $(PWD):/vapor -p 8080:8080 vapor")
    }
}
