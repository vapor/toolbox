// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "vapor", targets: ["Executable"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.2.0"),
        .package(url: "https://github.com/vapor/console-kit.git", .branch("master")),
        .package(url: "https://github.com/loganwright/async-websocket-client.git", .branch("master")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .branch("master")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0"),
        .package(url: "https://github.com/tanner0101/mustache.git", .branch("master")),
    ],
    targets: [
        .target(name: "VaporToolbox", dependencies: [
            "ConsoleKit",
            "CloudCommands",
            "Globals",
            "NIO",
            "AsyncHTTPClient",
            "AsyncWebSocketClient",
            "Yams",
            "Mustache"
        ]),
        .target(name: "CloudCommands", dependencies: [
            "ConsoleKit",
            "AsyncHTTPClient",
            "CloudAPI",
            "Globals",
        ]),
        .target(name: "CloudAPI", dependencies: [
            "Globals",
            "AsyncHTTPClient",
            "AsyncWebSocketClient",
        ]),
        .target(name: "Globals", dependencies: [
            "NIO",
        ]),
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
