// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DozeLatch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DozeLatch", targets: ["DozeLatch"])
    ],
    targets: [
        .target(
            name: "DozeLatchCore"
        ),
        .executableTarget(
            name: "DozeLatch",
            dependencies: ["DozeLatchCore"]
        ),
        .executableTarget(
            name: "DozeLatchChecks",
            dependencies: ["DozeLatchCore"]
        )
    ]
)
