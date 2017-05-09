extension CloudAPI {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func project(
        for arguments: [String],
        using console: ConsoleProtocol
    ) throws -> Project {
        let projs = try console.loadingBar(title: "Loading projects", ephemeral: true) {
            return try projects(size: 999)
        }
        
        guard projs.data.count > 0 else {
            console.warning("No projects found.")
            console.detail("Create project", "vapor cloud create proj")
            throw "Project required"
        }
        
        let proj = try console.giveChoice(
            title: "Which project?",
            in: projs.data
        )
        
        console.detail("proj", proj.name)
        return proj
    }
}

extension Project: CustomStringConvertible {
    public var description: String {
        return "\(name)"
    }
}
