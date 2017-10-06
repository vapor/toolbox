public final class CreateOrganization: Command {
    public let id = "org"
    
    public let signature: [Argument] = [
        Option(name: "name", help: ["The name for this organization"]),
    ]
    
    public let help: [String] = [
        "Creates a new organization."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        try createOrganization(with: arguments)
    }
    
    private func createOrganization(with arguments: [String]) throws {
        let name: String
        if let n = arguments.option("name") {
            name = n
        } else {
            name = console.ask("What name for this organization?")
            console.clear(lines: 2)
        }
        console.detail("organization", name)
        try console.verifyAboveCorrect()
        
        let org = Organization(
            id: nil,
            name: name,
            credits: 0,
            wallet: nil,
            refillThreshold: nil,
            refillCredits: nil
        )
        
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        _ = try console.loadingBar(title: "Creating organization '\(name)'") {
            return try cloud.create(org)
        }
    }
}
