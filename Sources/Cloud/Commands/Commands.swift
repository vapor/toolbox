@_exported import Console
import Foundation

public func group(_ console: ConsoleProtocol) throws -> Group {
    // create api factories
    let clientFactory = ClientFactory<EngineClient>()
    let cloudFactory = try CloudAPIFactory(
        baseURL: cloudURL,
        clientFactory
    )
    
    return Group(
        id: "cloud",
        commands: [
            // User
            Login(console: console),
            Logout(console: console),
            Signup(console: console),
            Refresh(console: console),
            Me(console: console),
            // Debug
            TokenLog(console: console),
            Dump(console: console),
            // App Debugging
            CloudLogs(console: console),
            // Info
            List(console: console),
            // Deploy
            DeployCloud(console: console),
            // Create
            Create(console, cloudFactory),
            // Run remote commands
            CloudRun(console: console),
            CloudConfigs(console: console),
            // Temporarily disabling not ready commands
            // Add(console: console),
            // CloudSetup(console: console),
            // CloudInit(console: console)
            OpenDatabase(console, cloudFactory)
        ],
        help: [
            "Commands for interacting with Vapor Cloud."
        ]
    )
}
