@_exported import Console

public func group(_ console: ConsoleProtocol) -> Group {
    return Group(
        id: "cloud",
        commands: [
            Login(console: console),
            Logout(console: console),
            Signup(console: console),
            Me(console: console),
            Refresh(console: console),
            TokenLog(console: console),
            Organizations(console: console),
            Projects(console: console),
            Applications(console: console),
            DeployCloud(console: console),
            Dump(console: console),
            DeployCloud(console: console),
            Create(console: console),
            Add(console: console),
            CloudSetup(console: console),
            CloudInit(console: console)
        ],
        help: [
            "Commands for interacting with Vapor Cloud."
        ]
    )
}
