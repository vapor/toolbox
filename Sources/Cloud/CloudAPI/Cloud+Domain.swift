extension ConsoleProtocol {
    /// Dynamically chooses an environment based on
    /// input arguments and lists from the Cloud API.
    func domains(
        environment: ModelOrIdentifier<Environment>,
        application: ModelOrIdentifier<Application>,
        arguments: [String],
        cloudFactory: CloudAPIFactory
    ) throws -> Domain {
        let domain: Domain
        
        let domains: [Domain] = try loadingBar(title: "Loading environments", ephemeral: true) {
            do {
                return try cloudFactory
                    .makeAuthedClient(with: self)
                    .domains(for: environment, on: application)
            } catch let error as AbortError where error.status == .notFound {
                return []
            }
        }
        
        if domains.count == 0 {
            warning("No domains found.")
            detail("Create domain", "vapor cloud create domain")
            if confirm("Would you like to create a domain now?") {
                let create = CreateDomain(self, cloudFactory)
                domain = try create.createDomain(with: arguments + [
                    "--app=\(application.assertIdentifier())",
                    "--env=\(environment.assertIdentifier())",
                ])
            } else {
                throw "Environment required"
            }
        } else {
            domain = try giveChoice(
                title: "Which domain?",
                in: domains
            )
        }
        
        detail("domain", domain.domain)
        return domain
    }
}

extension Domain: CustomStringConvertible {
    public var description: String {
        return domain + path
    }
}
