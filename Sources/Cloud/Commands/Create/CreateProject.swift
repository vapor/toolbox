public final class CreateProject: Command {
    public let id = "proj"
    
    public let signature: [Argument] = [
        Option(name: "name", help: ["The name for this project"]),
    ]
    
    public let help: [String] = [
        "Creates a new project."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        try createProject(with: arguments)
    }
    
    private func createProject(with arguments: [String]) throws {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let org = try cloud.organization(for: arguments, using: console)
        
        let name: String
        if let n = arguments.option("name") {
            name = n
        } else {
            name = console.ask("What name for this project?")
            console.clear(lines: 2)
        }
        console.detail("project", name)
        try console.verifyAboveCorrect()
        
        let proj = Project(
            id: nil,
            name: name,
            color: "72ABC3",
            organization: .model(org)
        )
        
        _ = try console.loadingBar(title: "Creating project '\(name)'") {
            return try cloud.create(proj)
        }
    }
}
