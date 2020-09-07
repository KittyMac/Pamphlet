// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Pamphlet",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "Pamphlet", targets: ["Pamphlet"]),
        .library(name: "PamphletFramework", targets: ["PamphletFramework"]),
		.library(name: "libmcpp", targets: ["libmcpp"])
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
            dependencies: ["Ipecac", "libmcpp"]),
        .target(
            name: "libmcpp"),
        .testTarget(
            name: "PamphletFrameworkTests",
            dependencies: ["PamphletFramework"]),
    ]
)
