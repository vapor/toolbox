// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "toolbox",
    platforms: [
       .macOS(.v10_15),
    ],
    products: [
        .executable(name: "vapor", targets: ["Executable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.18.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.0"),
        .package(url: "https://github.com/tanner0101/mustache.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.2.0"),
    ],
    targets: [
        .target(name: "VaporToolbox", dependencies: [
            .product(name: "ConsoleKit", package: "console-kit"),
            .product(name: "Mustache", package: "mustache"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "Yams", package: "Yams"),
        ]),
        .testTarget(name: "VaporToolboxTests", dependencies: [
            .target(name: "VaporToolbox"),
        ]),
        .executableTarget(name: "Executable", dependencies: [
            .target(name: "VaporToolbox"),
        ]),
    ]
)
