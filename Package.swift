// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
        .package(url: "https://github.com/tanner0101/swift-syntax.git", .branch("static")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf-kit.git", .branch("file-in-error")),
        .package(url: "git@github.com:vapor/console.git", .branch("master")),
        .package(url: "https://github.com/loganwright/async-websocket-client.git", .branch("master")),
        .package(url: "https://github.com/swift-server/swift-nio-http-client.git", .branch("master")),
    ],
    targets: [
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: [
            "LinuxTestsGeneration",
            "ConsoleKit",
            "CloudCommands",
            "Globals",
            "NIO",
            "AsyncHTTPClient",
            "LeafKit",
            "AsyncWebSocketClient",
        ]),
        .target(name: "LinuxTestsGeneration", dependencies: [
            "SwiftSyntax",
            "Globals",
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
        .testTarget(name: "LinuxTestsGenerationTests", dependencies: [
            "LinuxTestsGeneration",
        ]),
        // Runnable module, executes the main command group.
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
