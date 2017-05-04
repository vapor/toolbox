public final class CreateApplication: Command {
    public let id = "app"
    
    public let signature: [Argument] = [
        Option(name: "name", help: ["The readable name for this application"]),
        Option(name: "slug", help: [
            "The slug name for this application",
            "This will be used to create the URL (slug.vapor.cloud)"
        ]),
    ]
    
    public let help: [String] = [
        "Creates a new application."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        _ = try createApplication(with: arguments)
    }
    
    func createApplication(with arguments: [String]) throws -> Application {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let proj = try cloud.project(for: arguments, using: console)
        
        let name: String
        if let n = arguments.option("name") {
            name = n
        } else {
            name = console.ask("What name for this application?")
            console.clear(lines: 2)
        }
        console.detail("app", name)
        
        let slug: String
        if let n = arguments.option("slug") {
            slug = n
        } else {
            console.print("Slugs are used to create the app's URL (slug.vapor.cloud)")
            slug = console.ask("What slug for this application?")
            console.clear(lines: 3)
        }
        console.detail("slug", slug)
        
        try console.verifyAboveCorrect()
        
        let app = Application(
            id: nil,
            project: .model(proj),
            repoName: slug,
            name: name
        )
        
        return try console.loadingBar(title: "Creating application '\(name)'") {
            return try cloud.create(app)
        }
    }
}
