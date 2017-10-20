public final class ShowDatabaseInfo {
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func login(dbInfo: DatabaseInfo) throws {
        if (dbInfo.type == "postgresql") {
            _ = try console.foregroundExecute(
                program: "psql",
                arguments: [
                    "postgresql://\(dbInfo.username):\(dbInfo.password)@\(dbInfo.hostname):\(dbInfo.port)/\(dbInfo.username)",
                ])
        } else if (dbInfo.type == "mongodb") {
            _ = try console.foregroundExecute(
                program: "mongo",
                arguments: [
                    "\(dbInfo.hostname):\(dbInfo.port)/\(dbInfo.username)",
                    "-u",
                    "\(dbInfo.username)",
                    "-p",
                    "\(dbInfo.password)",
                ])
        } else {
            _ = try console.foregroundExecute(
                program: "mysql",
                arguments: [
                    "-u",
                    "\(dbInfo.username)",
                    "-p\(dbInfo.password)",
                    "-h",
                    "\(dbInfo.hostname)",
                    "-P",
                    "\(dbInfo.port)",
                    "\(dbInfo.username)"
                ])
        }
        
        exit(0)
    }
    
    public func showInfo(dbInfo: DatabaseInfo, application: String?) throws -> Bool {
        if (dbInfo.ended) {
            exit(0)
        }
        
        let app = application ?? ""
        
        let token = try Token.global(with: console)
        //let environments = try applicationApi.environments.all(for: app, with: token)
        let environment = try applicationApi.environments.get(forRepo: app, forEnvironment: dbInfo.environmentId, with: token)
        
        console.info("")
        console.detail("Environment", "\(environment.name)")
        console.detail("Hostname", "\(dbInfo.hostname)")
        console.detail("Port", "\(dbInfo.port)")
        console.detail("Username", "\(dbInfo.username)")
        console.detail("Password", "\(dbInfo.password)")
        
        
        
        return true
    }
}
