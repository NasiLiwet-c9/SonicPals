// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "SonarCore",
    platforms: [
        .iOS(.v26),
        .visionOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SonarCore",
            targets: ["SonarCore"]
        )
    ],
    targets: [
        .target(name: "SonarCore"),
        .testTarget(
            name: "SonarCoreTests",
            dependencies: ["SonarCore"]
        )
    ]
)
