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
        .package(url: "https://github.com/tanner0101/mustache.git", .branch("master")),
        .package(url: "https://github.com/vapor/console-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "VaporToolbox", dependencies: [
            "ConsoleKit",
            "Mustache",
            "NIO",
            "Yams"
        ]),
        .target(name: "Executable", dependencies: ["VaporToolbox"]),
    ]
)
