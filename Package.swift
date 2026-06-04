// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ctrlspace",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ctrlspace", targets: ["ctrlspace"])
    ],
    targets: [
        .executableTarget(
            name: "ctrlspace",
            path: "Sources/ctrlspace"
        )
    ]
)
