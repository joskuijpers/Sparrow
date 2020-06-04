// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowMesh",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "SparrowMesh",
                 targets: ["SparrowMesh"]),
    ],
    dependencies: [
        .package(path: "../SparrowBinaryCoder"),
    ],
    targets: [
        .target(
            name: "SparrowMesh",
            dependencies: ["SparrowBinaryCoder"]),
        .testTarget(
            name: "SparrowMeshTests",
            dependencies: ["SparrowMesh"]),
    ]
)
