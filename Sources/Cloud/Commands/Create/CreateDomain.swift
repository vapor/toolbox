public final class CreateDomain: Command {
    public let id = "domain"
    
    public let signature: [Argument] = [
        Option(name: "domain", help: ["The domain name"]),
        Option(name: "path", help: ["Optional domain path. Defaults to /"]),
    ]
    
    public let help: [String] = [
        "Creates a new domain."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        _ = try createDomain(with: arguments)
    }
    
    internal func createDomain(with arguments: [String]) throws -> Domain {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        
        let name: String
        if let n = arguments.option("domain") {
            name = n
        } else {
            name = console.ask("What domain name?")
            console.clear(lines: 2)
        }
        console.detail("domain", name)
        try console.verifyAboveCorrect()
        
        let domain = Domain(
            id: nil,
            environment: .model(env),
            certificate: nil,
            domain: name,
            path: arguments.option("path")
        )
        
        let new = try console.loadingBar(title: "Creating domain '\(name)'") {
            return try cloudFactory
                .makeAuthedClient(with: console)
                .create(domain, on: .model(app))
        }
        console.print("New domains will take effect on the next deploy.")
        return new
    }
}
