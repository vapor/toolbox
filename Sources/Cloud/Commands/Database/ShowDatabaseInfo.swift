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
    
    public func createConfig(dbInfo: DatabaseInfo, application: String?) throws -> Bool {
        if (dbInfo.ended) {
            exit(0)
        }
        
        let app = application ?? ""
        
        let token = try Token.global(with: console)
        //let environments = try applicationApi.environments.all(for: app, with: token)
        let environment = try applicationApi.environments.get(forRepo: app, forEnvironment: dbInfo.environmentId, with: token)
        
        console.detail("Environment", "\(environment.name)")
        
        var connectUrl = ""
        
        switch dbInfo.type {
        case "mysql":
            connectUrl = "http://"
        case "postgresql":
            connectUrl = "postgresql://"
        case "mongodb":
            connectUrl = "mongodb://"
        default:
            console.error("Could not find type")
            exit(1)
        }
        
        connectUrl += "\(dbInfo.username):\(dbInfo.password)@\(dbInfo.hostname):\(dbInfo.port)/\(dbInfo.username)"
        
        //console.detail("DB_\(dbInfo.type.uppercased())", connectUrl)
        
        console.info("")
        
        _ = try console.foregroundExecute(
            program: "vapor",
            arguments: [
                "cloud",
                "config",
                "modify",
                "-y",
                "--app=\(app)",
                "--env=\(environment)",
                "\(dbInfo.token)=\(connectUrl)"
            ])
        
        console.success("Add \(dbInfo.token) to your database config file, and redeploy your application.")
        
        return true
    }
    
    public func listServers(dbInfo: DatabaseListObj, application: String) throws -> Bool {
        if (dbInfo.ended) {
            exit(0)
        }
        
        
        console.info("")
        //print(dbInfo)
        console.info(dbInfo.token + " (", newLine: false)
        
        switch try ServerStatus(string: dbInfo.status) {
        case .running:
            console.success("Running", newLine: false)
        case .stopped:
            console.error("Stopped", newLine: false)
        case .deleted:
            console.error("Deleted", newLine: false)
        case .modifying:
            console.warning("Modifying", newLine: false)
        case .restarting:
            console.warning("Restarting", newLine: false)
        default:
            exit(0)
        }
        
        console.info(")")
        
        console.detail("Name", dbInfo.name)
        console.detail("Type", "\(dbInfo.type) (\(dbInfo.version))")
        console.detail("Host", dbInfo.host)
        console.detail("Size", dbInfo.size)
        
        return true
    }
    
    
}

extension ServerStatus {
    init(string: String) throws {
        switch string {
        case "running":
            self = .running
        case "stopped":
            self = .stopped
        case "deleted":
            self = .deleted
        case "modifying":
            self = .modifying
        case "restarting":
            self = .restarting
        default:
            exit(1)
        }
    }
}

public enum ServerStatus: String {
    case running
    case stopped
    case deleted
    case modifying
    case restarting
}
