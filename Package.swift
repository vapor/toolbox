// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "toolbox",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "vapor", targets: ["VaporToolbox"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "VaporToolbox",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Mustache", package: "swift-mustache"),
                .product(name: "Yams", package: "yams"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaporToolboxTests",
            dependencies: [
                .target(name: "VaporToolbox")
            ],
            resources: [
                .copy("Manifests")
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny")
    ]
}
