// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SparrowEngine2",
    platforms: [
        .macOS(.v10_13) // 13 for metal
    ],
    products: [
        .library(
            name: "SparrowEngine2",
            targets: ["SparrowEngine2"]),
    ],
    dependencies: [
        .package(path: "../SparrowAsset"),
        .package(path: "../SparrowECS"),
    ],
    targets: [
        .target(
            name: "SparrowEngine2",
            dependencies: ["SparrowAsset", "SparrowECS"]),
        .testTarget(
            name: "SparrowEngine2Tests",
            dependencies: ["SparrowEngine2"]),
    ]
)
