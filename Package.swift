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
        .Package(url: "https://github.com/vapor/console.git", majorVersion: 2),
        
        // JSON parsing / serializing.
        .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
        
        // Vapor web framework.
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        
        // Redis
        .Package(url: "https://github.com/vapor/redis.git", majorVersion: 2),
    ]
)
