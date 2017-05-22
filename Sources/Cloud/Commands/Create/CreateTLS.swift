import Redis
import Dispatch

public final class CreateTLS: Console.Command {
    public let id = "tls"
    
    public let signature: [Argument] = [
        Option(name: "force", help: ["Will force TLS on the chosen domain"]),
    ]
    
    public let help: [String] = [
        "Adds TLS (SSL) to a domain."
    ]
    
    public let console: ConsoleProtocol
    public let cloudFactory: CloudAPIFactory
    
    public init(_ console: ConsoleProtocol, _ cloudFactory: CloudAPIFactory) {
        self.console = console
        self.cloudFactory = cloudFactory
    }
    
    public func run(arguments: [String]) throws {
        try createTLS(with: arguments)
    }
    
    private func createTLS(with arguments: [String]) throws {
        let app = try console.application(for: arguments, using: cloudFactory)
        let env = try console.environment(
            on: .model(app),
            for: arguments,
            using: cloudFactory
        )
        
        let domain = try console.domains(
            environment: .model(env),
            application: .model(app),
            arguments: arguments,
            cloudFactory: cloudFactory
        )
        
        let redis = try Redis.Client.cloudRedis()
        
        let channel = "tls_log_\(app.repoName)_\(env.name)_\(domain.domain)"
        
        var message = JSON()
        try message.set("channel", channel)
        try message.set("app", app.repoName)
        try message.set("environment", env.name)
        try message.set("domain", domain.domain)
        try message.set("force_tls", arguments.option("force")?.bool ?? false)
        
        console.info("Adding TLS...")
        try redis.publish(channel: "letsEncryptRequest", message)
        
        let group = DispatchGroup()
        group.enter()
        let item = DispatchWorkItem {
            try! redis.subscribe(channel: channel) { data in
                guard let data = data else {
                    return
                }
                
                switch data {
                case .array(let array):
                    guard array.count == 3 else {
                        return
                    }
                    
                    guard let raw = array[2] else {
                        return
                    }
                    
                    switch raw {
                    case .bulk(let bytes):
                        let message = bytes.makeString()
                        if message == "exit" {
                            group.leave()
                        } else {
                            self.console.print(message)
                        }
                    default:
                        return
                    }
                default:
                    return
                }
            }
        }
        DispatchQueue.global().async(execute: item)
        group.wait()
    }
}
