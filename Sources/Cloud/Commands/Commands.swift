@_exported import Console

public func group(_ console: ConsoleProtocol) -> Group {
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
            Create(console: console),
            // Temporarily disabling not ready commands
            // Add(console: console),
            // CloudSetup(console: console),
            // CloudInit(console: console)
        ],
        help: [
            "Commands for interacting with Vapor Cloud."
        ]
    )
}
