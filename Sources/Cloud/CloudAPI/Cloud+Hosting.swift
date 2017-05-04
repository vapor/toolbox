extension ConsoleProtocol {
    /// Dynamically chooses a hosting service based on
    /// input arguments and lists from the Cloud API.
    func hosting(
        on app: ModelOrIdentifier<Application>,
        for arguments: [String],
        using cloudFactory: CloudAPIFactory
    ) throws -> Hosting {
        let hosting: Hosting
        do {
            hosting = try loadingBar(title: "Loading hosting service", ephemeral: true) {
                return try cloudFactory
                    .makeAuthedClient(with: self)
                    .hosting(for: app)
            }
            
        } catch let error as AbortError where error.status == .notFound {
            warning("No hosting service found.")
            if confirm("Would you like to add hosting?") {
                let create = CreateHosting(self, cloudFactory)
                hosting = try create.createHosting(with: arguments + ["--app=\(app.assertIdentifier())"])
            } else {
                detail("Create hosting", "vapor cloud create hosting")
                throw "Hosting required"
            }
        }
        
        detail("git url", hosting.gitURL)
        return hosting
    }
}

extension Hosting: CustomStringConvertible {
    public var description: String {
        return "\(gitURL)"
    }
}
