// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "Pamphlet",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "Pamphlet", targets: ["Pamphlet"]),
        .library(name: "PamphletFramework", targets: ["PamphletFramework"]),
		.library(name: "libmcpp", targets: ["libmcpp"]),
        .plugin(name: "PamphletPlugin", targets: ["PamphletPlugin"])
    ],
    dependencies: [
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Pamphlet",
            dependencies: [
                "Hitch",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PamphletFramework"
            ]
        ),
        .plugin(
            name: "PamphletPlugin",
            capability: .buildTool(),
            dependencies: ["Pamphlet"]
        ),
        .target(
            name: "PamphletFramework",
            dependencies: ["Hitch", "libmcpp"]),
        .target(
            name: "libmcpp"),
        .testTarget(
            name: "PamphletFrameworkTests",
            dependencies: [
                "PamphletFramework"
            ],
            plugins: [
                .plugin(name: "PamphletPlugin")
            ]),
    ]
)
