// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowBinaryCoder",
    products: [
        .library(
            name: "SparrowBinaryCoder",
            targets: ["SparrowBinaryCoder"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SparrowBinaryCoder",
            dependencies: []),
        .testTarget(
            name: "SparrowBinaryCoderTests",
            dependencies: ["SparrowBinaryCoder"]),
    ]
)
