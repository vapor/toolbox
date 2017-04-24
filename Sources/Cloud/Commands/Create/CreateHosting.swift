public final class CreateHosting: Command {
    public let id = "hosting"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
           "The application to which hosting will be added"
        ]),
        Option(name: "gitURL", help: [
            "The Git URL to clone when deploying this application",
            "Note: must be in the SSH format (starting with git@...)"
        ]),
    ]
    
    public let help: [String] = [
        "Adds hosting service to an application."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        try createHosting(with: arguments)
    }
    
    private func createHosting(with arguments: [String]) throws {
        let cloud = try cloudFactory.makeAuthedClient(with: console)
        let app = try cloud.application(for: arguments, using: console)
        
        let gitURL: String
        if let n = arguments.option("gitURL") {
            gitURL = n
        } else {
            console.warning("Git URL's must be in SSH format (git@github.com:...)")
            gitURL = console.ask("What Git URL should we clone when deploying?")
            console.clear(lines: 3)
        }
        console.detail("gitURL", gitURL)
        try console.verifyAboveCorrect()
        
        let hosting = Hosting(
            id: nil,
            application: .model(app),
            gitURL: gitURL
        )
        
        _ = try console.loadingBar(title: "Adding hosting service to '\(app.repoName)'") {
            return try cloud.create(hosting)
        }
    }
}
