extension CloudAPI {
    /// Dynamically chooses a hosting service based on
    /// input arguments and lists from the Cloud API.
    func hosting(
        on app: ModelOrIdentifier<Application>,
        for arguments: [String],
        using console: ConsoleProtocol
    ) throws -> Hosting {
        do {
            let hosting = try console.loadingBar(title: "Loading hosting service", ephemeral: true) {
                return try self.hosting(for: app)
            }
            
            console.detail("git url", hosting.gitURL)
            return hosting
        } catch let error as AbortError where error.status == .notFound {
            console.warning("No hosting service found.")
            console.detail("Create hosting", "vapor cloud create hosting")
            throw "Hosting required"
        }
    }
}

extension Hosting: CustomStringConvertible {
    public var description: String {
        return "\(gitURL)"
    }
}
