import PackageDescription

let package = Package(
    name: "VaporToolbox",
    targets: [
        Target(name: "VaporToolbox", dependencies: ["Cloud", "Shared"]),
        Target(name: "Executable", dependencies: ["VaporToolbox"]),
        Target(name: "Cloud", dependencies: ["Shared"]),
        Target(name: "Shared"),
    ],
    dependencies: [
        // Vapor Cloud clients.
        .Package(url: "git@github.com:vapor-cloud/clients.git", majorVersion: 0),
        
        // Core console protocol.
        .Package(url: "https://github.com/vapor/console.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        
        // JSON parsing / serializing.
        .Package(url: "https://github.com/vapor/json.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        
        // Vapor web framework.
        .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        
        // Redis
        .Package(url: "https://github.com/vapor/redis.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
    ]
)
