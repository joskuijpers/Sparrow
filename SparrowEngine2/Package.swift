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
            targets: ["CSparrowEngine", "SparrowEngine2"]
        )
    ],
    dependencies: [
        .package(path: "../SparrowMesh"),
        .package(path: "../SparrowECS"),
    ],
    targets: [
        .target(
            name: "SparrowEngine2",
            dependencies: ["SparrowMesh", "SparrowECS", "CSparrowEngine"],
            path: "Sources/SparrowEngine2"
        ),
        .target(
            name: "CSparrowEngine",
            path: "Sources/CSparrowEngine"
        ),
        .testTarget(
            name: "SparrowEngine2Tests",
            dependencies: ["SparrowEngine2"]
        ),
    ]
)
