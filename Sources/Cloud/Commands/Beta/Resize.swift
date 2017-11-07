public final class Resize: Command {
    public let id = "resize"
    
    public let signature: [Argument] = [
        Option(name: "app", help: [
            "The slug name of the application to deploy",
            "This will be automatically detected if your are",
            "in a Git controlled folder with a remote matching",
            "the application's hosting Git URL."
            ]),
        Option(name: "env", help: [
            "The name of the environment to deploy to.",
            "This will always be required to deploy, however",
            "omitting the flag will result in a selection menu."
            ])
    ]
    
    public let help: [String] = [
        "Change replica size"
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(on: .model(app), for: arguments, using: cloudFactory)
        let token = try Token.global(with: console)
        
        let replicaSize = try self.size(for: arguments)
        
        let resize = try applicationApi.deploy.resize(
            repo: app.repoName,
            envName: env.name,
            replicaSize: replicaSize.rawValue,
            with: token
        )
        
        console.info("Connecting to build logs ...")
        var waitingInQueue = console.loadingBar(title: "Waiting in Queue")
        defer { waitingInQueue.fail() }
        waitingInQueue.start()

        guard let id = try resize.deployment.assertIdentifier().string else {
            throw "Invalid deployment identifier"
        }
        
        var logsBar: LoadingBar?
        try CloudRedis.subscribeDeployLog(id: id) { update in
            waitingInQueue.finish()
            
            if update.type == .start {
                logsBar = self.console.loadingBar(title: update.message)
                logsBar?.start()
            } else if update.success {
                logsBar?.finish()
            } else {
                logsBar?.fail()
            }
            
            if !update.success && !update.message.trim().isEmpty {
                let printable = update.message
                self.console.warning(printable)
                throw "Resize failed."
            }
        }
    }
    
    private func size(for arguments: [String]) throws -> ReplicaSizes {
        let size: ReplicaSizes
        
        console.pushEphemeral()
        
        size = try console.giveChoice(
            title: "Which size?",
            in: ReplicaSizes.all
        ) { type in
            switch type {
            case .free:
                return "Free - $0/month per replica"
            case .hobby:
                return "Hobby - $6/month per replica"
            case .small:
                return "Small - $30/month per replica"
            case .medium:
                return "Medium - $65/month per replica"
            case .large:
                return "Large - $225/month per replica"
            case .xlarge:
                return "X Large - $375/month per replica"
            }
        }
        
        console.popEphemeral()
        
        console.detail("size", "\(size)")
        return size
    }
    
    public enum Sizes {
        case free
        case hobby
        case small
        case medium
        case large
        case xlarge
    }
}

public typealias ReplicaSizes = Resize.Sizes

extension ReplicaSizes {
    static let all: [ReplicaSizes] = [.free, .hobby, .small, .medium, .large, .xlarge]
    public var rawValue: String {
        switch self {
        case .free:
            return "free"
        case .hobby:
            return "hobby"
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        case .xlarge:
            return "xlarge"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "free":
            self = .free
        case "hobby":
            self = .hobby
        case "small":
            self = .small
        case "medium":
            self = .medium
        case "large":
            self = .large
        case "xlarge":
            self = .xlarge
        default:
            return nil
        }
    }
}
