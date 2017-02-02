import Console

public final class DockerEnter: Command {
    public let id = "enter"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Enters the Docker image container.",
        "Useful for debugging."
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

        console.info("Copy and run the following line:")
        console.print("docker run --rm -it -v $(PWD):/vapor --entrypoint bash vapor")
    }
}
