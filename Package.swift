// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "toolbox",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "vapor", targets: ["Executable"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master")),
        .package(url: "https://github.com/jpsim/Yams.git", .branch("master")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .branch("master")),
        .package(url: "https://github.com/tanner0101/mustache.git", .branch("master")),
        .package(url: "https://github.com/vapor/console-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/websocket-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "VaporToolbox", dependencies: [
            "AsyncHTTPClient",
            "ConsoleKit",
            "CloudCommands",
            "Globals",
            "Mustache",
            "NIO",
            "WebSocketKit",
            "Yams"
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
            "WebSocketKit"
        ]),
        .target(name: "Globals", dependencies: [
            "ConsoleKit",
            "NIO"
        ]),
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
