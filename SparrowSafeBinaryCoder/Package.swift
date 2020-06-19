// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SparrowSafeBinaryCoder",
    products: [
        .library(
            name: "SparrowSafeBinaryCoder",
            targets: ["SparrowSafeBinaryCoder"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/SomeRandomiOSDev/CBORCoding.git", from: "1.0.0")
        .package(path: "../../CBORCoding")
    ],
    targets: [
        .target(
            name: "SparrowSafeBinaryCoder",
            dependencies: ["CBORCoding"]),
        .testTarget(
            name: "SparrowSafeBinaryCoderTests",
            dependencies: ["SparrowSafeBinaryCoder"]),
    ]
)
