// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowECS",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "SparrowECS",
                 targets: ["SparrowECS"]),
    ],
    dependencies: [
        .package(path: "../SparrowSafeBinaryCoder"),
    ],
    targets: [
        .target(
            name: "SparrowECS",
            dependencies: ["SparrowSafeBinaryCoder"]),
        .testTarget(
            name: "SparrowECSTests",
            dependencies: ["SparrowECS"]),
    ]
)
