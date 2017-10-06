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
        _ = try createProject(with: arguments)
    }
    
    func createProject(with arguments: [String]) throws -> Project {
        let cloud = try cloudFactory.makeAuthedClient(with: console)

        console.pushEphemeral()

        console.info("Creating a project")
        console.print("Projects are a way to group applications together.")
        console.print("If you are an app developer, you might create a new project")
        console.print("for each client to keep things organized.")

        console.info("Choosing an organization")
        console.print("If paid services are added to applications in this project,")
        console.print("they will be billed to the project's organization.")
        let org = try cloud.organization(for: arguments, using: console)

        console.popEphemeral()
        
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


        
        return try console.loadingBar(title: "Creating project '\(name)'") {
            return try cloud.create(proj)
        }
    }
}
