extension ConsoleProtocol {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func project(
        for arguments: [String],
        using cloudFactory: CloudAPIFactory
    ) throws -> Project {
        pushEphemeral()
        
        let projs = try loadingBar(title: "Loading projects", ephemeral: true) {
            return try cloudFactory
                .makeAuthedClient(with: self)
                .projects(size: 999)
        }
        
        guard projs.data.count > 0 else {
            warning("No projects found.")
            detail("Create project", "vapor cloud create proj")
            if confirm("Would you like to create a project now?") {
                let create = CreateProject(self, cloudFactory)
                return try create.createProject(with: arguments)
            } else {
                throw "Project required"
            }
        }
        
        let proj = try giveChoice(
            title: "Which project?",
            in: projs.data
        )
        
        popEphemeral()
        
        detail("proj", proj.name)
        return proj
    }
}

extension Project: CustomStringConvertible {
    public var description: String {
        return "\(name)"
    }
}
