// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowTextureLoader",
    platforms: [
        .macOS(.v10_13) // 13 for metal
    ],
    products: [
        .library(
            name: "SparrowTextureLoader",
            targets: ["CSparrowTextureLoader", "SparrowTextureLoader"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SparrowTextureLoader",
            dependencies: ["CSparrowTextureLoader"],
            path: "Sources/SparrowTextureLoader"
        ),
        .target(
            name: "CSparrowTextureLoader",
            path: "Sources/CSparrowTextureLoader"
        ),
        .testTarget(
            name: "SparrowTextureLoaderTests",
            dependencies: ["SparrowTextureLoader"]
        ),
    ]
)
