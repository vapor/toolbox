extension CloudAPI {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func organization(
        for arguments: [String],
        using console: ConsoleProtocol
    ) throws -> Organization {
        let orgs = try console.loadingBar(title: "Loading organizations", ephemeral: true) {
            return try organizations()
        }
        
        guard orgs.count > 0 else {
            console.warning("No organizations found.")
            console.detail("Create organization", "vapor cloud create org")
            throw "Organization required"
        }
        
        let org = try console.giveChoice(
            title: "Which organization?",
            in: orgs
        )
        
        console.detail("org", org.name)
        return org
    }
}

extension Organization: CustomStringConvertible {
    public var description: String {
        return "\(name)"
    }
}
