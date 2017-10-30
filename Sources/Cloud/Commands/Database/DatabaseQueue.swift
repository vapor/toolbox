public final class DatabaseQueue: Command {
    public let id = "beta"
    
    public let help: [String] = [
        "Apply to be part of the beta"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        
        console.info("")
        console.warning("Be aware, this feature is still in beta!, use with caution")
        console.info("")
        
        let token = try Token.global(with: console)
        let user = try adminApi.user.get(with: token)
        
        console.info("")
        
        let motivation = console.ask("Write a short motivation why you should be added to the list, include which Engine you use, and how many servers you plan to spin up.")
        
        try CloudRedis.betaQueue(
            console: console,
            email: user.email,
            motivation: motivation
        )
    }
}
