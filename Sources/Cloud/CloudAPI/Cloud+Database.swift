extension ConsoleProtocol {
    /// Dynamically chooses a hosting service based on
    /// input arguments and lists from the Cloud API.
    func database(
        for env: ModelOrIdentifier<Environment>,
        on app: ModelOrIdentifier<Application>,
        for arguments: [String],
        using cloudFactory: CloudAPIFactory
    ) throws -> Database? {
        let db: Database?
        
        pushEphemeral()
        
        let existing: Database? = try loadingBar(title: "Loading database service", ephemeral: true) {
            do {
                return try cloudFactory
                    .makeAuthedClient(with: self)
                    .database(for: env, on: app)
            } catch let error as AbortError where error.status == .notFound {
                return nil
            }
        }
        
        if let e = existing {
            db = e
        } else {
            warning("No database service found.")
            if confirm("Would you like to add a database?") {
                let create = CreateDatabase(self, cloudFactory)
                let args = try arguments + [
                    "--app=\(app.assertIdentifier())",
                    "--env=\(env.assertIdentifier())"
                ]
                db = try create.createDatabase(with: args)
            } else {
                detail("Create database", "vapor cloud create db")
                db = nil
            }
        }
        
        popEphemeral()
        
        if let db = db {
            detail("db", db.databaseServer.getModel()?.kind.description ?? "yes")
        } else {
            detail("db", "none")
        }
        
        return db
    }
}

extension DatabaseServer.Kind: CustomStringConvertible {
    public var description: String {
        return "\(self)"
    }
}
