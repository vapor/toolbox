@_exported import Console
import Foundation

public func group(_ console: ConsoleProtocol) throws -> Group {
    // create api factories
    let clientFactory = ClientFactory<EngineClient>()
    let cloudFactory = try CloudAPIFactory(
        baseURL: cloudURL,
        clientFactory
    )
    
    let create = Group(id: "create", commands: [
        CreateOrganization(console, cloudFactory),
        CreateProject(console, cloudFactory),
        CreateApplication(console, cloudFactory),
        CreateHosting(console, cloudFactory),
        CreateEnvironment(console, cloudFactory),
        CreateDatabase(console, cloudFactory),
        CreateDomain(console, cloudFactory),
        CreateTLS(console, cloudFactory),
    ], help: [
        "Create new instances of Vapor Cloud objects like",
        "applications, environments, databases, etc."
    ])
    
    let config = Group(id: "config", commands: [
        ConfigDump(console, cloudFactory),
        ConfigModify(console, cloudFactory),
        ConfigDelete(console, cloudFactory),
    ], help: [
        "View, create, modify, and delete environment configs"
    ])
    
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
            CloudLogs(console, cloudFactory),
            // Info
            List(console, cloudFactory),
            // Deploy
            DeployCloud(console, cloudFactory),
            // Create
            create,
            // Run remote commands
            CloudRun(console, cloudFactory),
            config,
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
