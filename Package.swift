// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "VaporToolbox",
    dependencies: [
        .package(url: "https://github.com/tanner0101/swift-syntax", .branch("static")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf-kit.git", from: "0.0.2"),
        .package(url: "git@github.com:vapor/console.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-websocket-client", .branch("master")),
        .package(url: "https://github.com/swift-server/swift-nio-http-client", .branch("master")),
        // ::vapor
    ],
    targets: [
        // All of the commands and logic that powers the Vapor toolbox
        .target(name: "VaporToolbox", dependencies: [
            "LinuxTestsGeneration",
            "ConsoleKit",
            "CloudCommands",
            "Globals",
            "NIO",
            "NIOHTTPClient",
            "LeafKit",
            "NIOWebSocketClient",
        ]),
        .target(name: "LinuxTestsGeneration", dependencies: [
            "SwiftSyntax",
            "Globals",
        ]),
        .target(name: "CloudCommands", dependencies: [
            "ConsoleKit",
            "NIOHTTPClient",
            "CloudAPI",
            "Globals",
        ]),
        .target(name: "CloudAPI", dependencies: [
            "Globals",
            "NIOHTTPClient",
            "NIOWebSocketClient",
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
