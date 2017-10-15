public final class DatabaseCreate: Command {
    public let id = "create"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
            ])
    ]
    
    public let help: [String] = [
        "Create a new database server"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        console.info("Create new database")
        
        let token = try Token.global(with: console)
        
        let app = try console.application(for: arguments, using: cloudFactory)
        
        let environments = try applicationApi.environments.all(for: app, with: token)
        
        var envArray: [String] = []
        
        console.info("")
        console.info("This creates a database server for the application: \(app)")
        console.info("It will also setup a database on the server for each of the environments:")
        
        try environments.forEach { val in
            console.info(" - \(val)")
            envArray.append("\(val.id ?? "")")
        }
        console.info("")
        
        let name = app.repoName
        let size = try self.size(for: arguments)
        let type = try self.type(for: arguments)
        let version = console.ask("Version: ")
        
        try CloudRedis.createDBServer(
            console: console,
            name: name,
            size: "\(size)",
            engine: "\(type)",
            engineVersion: version,
            environments: envArray
        )
    }
    
    private func size(for arguments: [String]) throws -> Size {
        let size: Size
        
        console.pushEphemeral()
        
        size = try console.giveChoice(
            title: "Which size?",
            in: Size.all
        ) { type in
            switch type {
            case .free:
                return "Free $0/month - (Details not finalized)"
            case .hobby:
                return "Hobby $9/month - (Details not finalized)"
            }
        }
    
        console.popEphemeral()
        
        console.detail("size", "\(size)")
        return size
    }
    
    private func type(for arguments: [String]) throws -> Type {
        let type: Type
        
        console.pushEphemeral()
        
        type = try console.giveChoice(
            title: "Which type?",
            in: Type.all
        ) { type in
            switch type {
            case .mysql:
                return "MySQL"
            case .postgresql:
                return "PostgreSQL"
            case .mongodb:
                return "MongoDB"
            }
        }
        
        console.popEphemeral()
        
        console.detail("type", "\(type)")
        return type
    }
    
    public enum Sizes {
        case free
        case hobby
    }
    
    public enum Types {
        case mysql
        case postgresql
        case mongodb
    }
}

public typealias Size = DatabaseCreate.Sizes

extension Size {
    static let all: [Size] = [.free, .hobby]
    public var rawValue: String {
        switch self {
        case .free:
            return "free"
        case .hobby:
            return "hobby"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "free":
            self = .free
        case "hobby":
            self = .hobby
        default:
            return nil
        }
    }
}

public typealias Type = DatabaseCreate.Types

extension Type {
    static let all: [Type] = [.mysql, .postgresql, .mongodb]
    public var rawValue: String {
        switch self {
        case .mysql:
            return "mysql"
        case .postgresql:
            return "postgresql"
        case .mongodb:
            return "mongodb"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "mysql":
            self = .mysql
        case "postgresql":
            self = .postgresql
        case "mongodb":
            self = .mongodb
        default:
            return nil
        }
    }
}
