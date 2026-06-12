// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ki",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ki", targets: ["ki"])
    ],
    targets: [
        .executableTarget(
            name: "ki",
            path: "Sources/ki"
        )
    ]
)
