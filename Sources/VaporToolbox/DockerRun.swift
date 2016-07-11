import Console

public final class DockerRun: Command {
    public let id = "run"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Runs the Docker image created with the",
        "Docker build command."
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

        let imageName = DockerBuild.imageName(version: swiftVersion)
        
        console.info("Copy and run the following line:")
        console.print("docker run --rm -it -v $(PWD):/vapor -p 8080:8080 \(imageName)")
    }

    static func imageName(version: String) -> String {
        return "qutheory/swift:\(version)"
    }
}
