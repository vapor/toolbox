extension CloudAPI {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func environment(
        in app: ModelOrIdentifier<Application>,
        for arguments: [String],
        using console: ConsoleProtocol
    ) throws -> Environment {
        let env: Environment
        
        if let envName = arguments.option("env")?.string {
            env = try environment(withId: Identifier(envName), for: app)
        } else {
            let envs = try console.loadingBar(title: "Loading environments", ephemeral: true) {
                return try environments(for: app)
            }
            
            guard envs.count > 0 else {
                console.warning("No environments found.")
                console.print("Use: vapor cloud create env")
                throw "Environment required"
            }
            
            env = try console.giveChoice(
                title: "Which environment?",
                in: envs
            )
        }
        
        console.detail("env", env.name)
        return env
    }
}

extension Environment: CustomStringConvertible {
    public var description: String {
        return "\(name)"
    }
}
