// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Hypnagogia",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Hypnagogia", targets: ["Hypnagogia"])
    ],
    targets: [
        .target(
            name: "HypnagogiaCore"
        ),
        .executableTarget(
            name: "Hypnagogia",
            dependencies: ["HypnagogiaCore"]
        ),
        .executableTarget(
            name: "HypnagogiaChecks",
            dependencies: ["HypnagogiaCore"]
        )
    ]
)
