// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowAsset",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "SparrowAsset",
                 targets: ["SparrowAsset"]),
    ],
    dependencies: [
        .package(path: "../SparrowBinaryCoder"),
    ],
    targets: [
        .target(
            name: "SparrowAsset",
            dependencies: ["SparrowBinaryCoder"]),
        .testTarget(
            name: "SparrowAssetTests",
            dependencies: ["SparrowAsset"]),
    ]
)
