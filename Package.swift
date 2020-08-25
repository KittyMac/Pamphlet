// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Pamphlet",
    products: [
        .executable(name: "Pamphlet", targets: ["Pamphlet"]),
        .library(name: "PamphletFramework", targets: ["PamphletFramework"])
    ],
    dependencies: [
		.package(url: "https://github.com/KittyMac/Ipecac.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "Pamphlet",
            dependencies: [
                "Ipecac",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PamphletFramework"
            ]
        ),
        .target(
            name: "PamphletFramework",
            dependencies: ["Ipecac"]),
        .testTarget(
            name: "PamphletFrameworkTests",
            dependencies: ["PamphletFramework"]),
    ]
)
