import Console

public final class ResourceGenerator: Generator {
    public static let supportedTypes = ["resource"]
    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func generate(arguments: [String]) throws {
        let argumentsToPassOn = arguments + ["--resource"]

        let modelGenerator = ModelGenerator(console: console)
        try modelGenerator.generate(arguments: argumentsToPassOn)

        let controllerGenerator = ControllerGenerator(console: console)
        try controllerGenerator.generate(arguments: argumentsToPassOn)
    }

}
