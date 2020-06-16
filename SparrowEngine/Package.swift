// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SparrowEngine",
    platforms: [
        .macOS(.v10_13) // 13 for metal
    ],
    products: [
        .library(
            name: "SparrowEngine",
            targets: ["CSparrowEngine", "SparrowEngine"]
        )
    ],
    dependencies: [
        .package(path: "../SparrowMesh"),
        .package(path: "../SparrowECS"),
    ],
    targets: [
        .target(
            name: "SparrowEngine",
            dependencies: ["SparrowMesh", "SparrowECS", "CSparrowEngine"],
            path: "Sources/SparrowEngine"
        ),
        .target(
            name: "CSparrowEngine",
            path: "Sources/CSparrowEngine"
        ),
        .testTarget(
            name: "SparrowEngineTests",
            dependencies: ["SparrowEngine"]
        ),
    ]
)
